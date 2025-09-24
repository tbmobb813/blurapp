// Clean, single-definition implementation for blur operations
#include <algorithm>
#include <vector>
#include <cstdint>
#include <cstring>
#include "blur.h"

static inline int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

// Naive separable box blur (horizontal then vertical) on an RGBA sub-rect.
static void boxBlurRGBA(uint8_t* p, int W, int H, int rx, int ry, const BlurRect& r) {
    rx = std::max(1, rx);
    ry = std::max(1, ry);

    const int x0 = clampi(r.x, 0, W - 1);
    const int y0 = clampi(r.y, 0, H - 1);
    const int x1 = clampi(r.x + r.w - 1, 0, W - 1);
    const int y1 = clampi(r.y + r.h - 1, 0, H - 1);

    const int w = x1 - x0 + 1;
    const int h = y1 - y0 + 1;
    if (w <= 0 || h <= 0) return;

    // Copy sub-rect into temporary buffer
    std::vector<uint8_t> tmp(static_cast<size_t>(w) * h * 4);
    for (int yy = 0; yy < h; ++yy) {
        const uint8_t* src = p + ((y0 + yy) * W + x0) * 4;
        uint8_t* dst = tmp.data() + (yy * w) * 4;
        std::copy(src, src + w * 4, dst);
    }

    // Horizontal pass -> horiz
    std::vector<uint8_t> horiz(static_cast<size_t>(w) * h * 4);
    for (int yy = 0; yy < h; ++yy) {
        for (int xx = 0; xx < w; ++xx) {
            int rsum = 0, gsum = 0, bsum = 0, asum = 0, cnt = 0;
            for (int k = -rx; k <= rx; ++k) {
                int sx = clampi(xx + k, 0, w - 1);
                const uint8_t* s = tmp.data() + (yy * w + sx) * 4;
                rsum += s[0]; gsum += s[1]; bsum += s[2]; asum += s[3];
                ++cnt;
            }
            uint8_t* d = horiz.data() + (yy * w + xx) * 4;
            d[0] = static_cast<uint8_t>(rsum / cnt);
            d[1] = static_cast<uint8_t>(gsum / cnt);
            d[2] = static_cast<uint8_t>(bsum / cnt);
            d[3] = static_cast<uint8_t>(asum / cnt);
        }
    }

    // Vertical pass back into tmp
    for (int yy = 0; yy < h; ++yy) {
        for (int xx = 0; xx < w; ++xx) {
            int rsum = 0, gsum = 0, bsum = 0, asum = 0, cnt = 0;
            for (int k = -ry; k <= ry; ++k) {
                int sy = clampi(yy + k, 0, h - 1);
                const uint8_t* s = horiz.data() + (sy * w + xx) * 4;
                rsum += s[0]; gsum += s[1]; bsum += s[2]; asum += s[3];
                ++cnt;
            }
            uint8_t* d = tmp.data() + (yy * w + xx) * 4;
            d[0] = static_cast<uint8_t>(rsum / cnt);
            d[1] = static_cast<uint8_t>(gsum / cnt);
            d[2] = static_cast<uint8_t>(bsum / cnt);
            d[3] = static_cast<uint8_t>(asum / cnt);
        }
    }

    // Blit back into original buffer
    for (int yy = 0; yy < h; ++yy) {
        uint8_t* dst = p + ((y0 + yy) * W + x0) * 4;
        const uint8_t* src = tmp.data() + (yy * w) * 4;
        std::copy(src, src + w * 4, dst);
    }
}

// Pixelate (block-average) over a rect
static void pixelateRGBA(uint8_t* p, int W, int H, int blockSize, const BlurRect& r) {
    const int x0 = clampi(r.x, 0, W - 1);
    const int y0 = clampi(r.y, 0, H - 1);
    const int x1 = clampi(r.x + r.w - 1, 0, W - 1);
    const int y1 = clampi(r.y + r.h - 1, 0, H - 1);
    const int bw = std::max(1, blockSize);

    for (int by = y0; by <= y1; by += bw) {
        for (int bx = x0; bx <= x1; bx += bw) {
            const int ex = std::min(bx + bw - 1, x1);
            const int ey = std::min(by + bw - 1, y1);

            uint32_t rsum = 0, gsum = 0, bsum = 0, asum = 0;
            uint32_t cnt = 0;
            for (int yy = by; yy <= ey; ++yy) {
                for (int xx = bx; xx <= ex; ++xx) {
                    uint8_t* pix = p + (yy * W + xx) * 4;
                    rsum += pix[0]; gsum += pix[1]; bsum += pix[2]; asum += pix[3];
                    ++cnt;
                }
            }

            if (cnt == 0) continue;
            const uint8_t rr = static_cast<uint8_t>(rsum / cnt);
            const uint8_t gg = static_cast<uint8_t>(gsum / cnt);
            const uint8_t bb = static_cast<uint8_t>(bsum / cnt);
            const uint8_t aa = static_cast<uint8_t>(asum / cnt);

            for (int yy = by; yy <= ey; ++yy) {
                for (int xx = bx; xx <= ex; ++xx) {
                    uint8_t* pix = p + (yy * W + xx) * 4;
                    pix[0] = rr; pix[1] = gg; pix[2] = bb; pix[3] = aa;
                }
            }
        }
    }
}

extern "C" int blur_apply_regions(uint8_t* pixels, int width, int height,
                                   const BlurRect* rects, int rect_count,
                                   int mode, int strength) {
    if (!pixels || width <= 0 || height <= 0) return -1;
    if (!rects || rect_count <= 0) return 0; // nothing to do

    for (int i = 0; i < rect_count; ++i) {
        const BlurRect r = rects[i];
        if (r.w <= 0 || r.h <= 0) continue;

        if (mode == 0) {
            int rx = std::max(1, strength);
            int ry = rx;
            boxBlurRGBA(pixels, width, height, rx, ry, r);
        } else if (mode == 1) {
            int block = std::max(1, strength);
            pixelateRGBA(pixels, width, height, block, r);
        } else {
            // unsupported mode
            return -2;
        }
    }

    return 0;
}