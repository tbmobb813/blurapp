#include <iostream>
#include <vector>
#include <cstdint>
#include "../include/blur.h"

int main() {
    const int W = 8, H = 8;
    std::vector<uint8_t> pixels(W * H * 4);
    // Fill with a checker pattern: left half red, right half blue
    for (int y = 0; y < H; ++y) {
        for (int x = 0; x < W; ++x) {
            int idx = (y * W + x) * 4;
            if (x < W/2) {
                pixels[idx+0] = 255; pixels[idx+1] = 0; pixels[idx+2] = 0; pixels[idx+3] = 255;
            } else {
                pixels[idx+0] = 0; pixels[idx+1] = 0; pixels[idx+2] = 255; pixels[idx+3] = 255;
            }
        }
    }

    BlurRect r;
    r.x = 0; r.y = 0; r.w = W; r.h = H;

    int rc = blur_apply_regions(pixels.data(), W, H, &r, 1, 1, 4); // pixelate block size 4
    if (rc != 0) {
        std::cerr << "blur_apply_regions returned " << rc << "\n";
        return 2;
    }

    // Verify that left and right halves have averaged colors for the block
    // Since left half started as pure red (255,0,0) and right half pure blue (0,0,255)
    // after pixelate with block size 4 each half should remain a dominant red/blue
    int idxL = ((H/2) * W + (W/4)) * 4;
    int idxR = ((H/2) * W + (3*W/4)) * 4;

    auto checkClose = [](int a, int b, int tol) {
        return std::abs(a - b) <= tol;
    };

    // Expect left pixel to be mostly red
    const int tol = 40; // allow some averaging tolerance
    const int leftR = pixels[idxL+0];
    const int leftG = pixels[idxL+1];
    const int leftB = pixels[idxL+2];
    if (!(leftR > leftG && leftR > leftB && leftR >= 255 - tol)) {
        std::cerr << "Left center not red enough: " << leftR << "," << leftG << "," << leftB << "\n";
        return 3;
    }

    // Expect right pixel to be mostly blue
    const int rightR = pixels[idxR+0];
    const int rightG = pixels[idxR+1];
    const int rightB = pixels[idxR+2];
    if (!(rightB > rightR && rightB > rightG && rightB >= 255 - tol)) {
        std::cerr << "Right center not blue enough: " << rightR << "," << rightG << "," << rightB << "\n";
        return 4;
    }

    std::cout << "Native pixelate smoke test OK\n";
    return 0;
}
