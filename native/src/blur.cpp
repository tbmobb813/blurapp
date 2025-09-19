#include <algorithm>
#include <vector>
#include <cstdint>
#include "blur.h"


static inline int clampi(int v, int lo, int hi){ return v < lo ? lo : (v > hi ? hi : v); }


// Naive box blur (approx Gaussian) on RGBA in-place over a rect
static void boxBlurRGBA(uint8_t* p, int W, int H, int rx, int ry, const BlurRect& r){
rx = std::max(1, rx); ry = std::max(1, ry);
const int x0 = clampi(r.x, 0, W-1);
const int y0 = clampi(r.y, 0, H-1);
const int x1 = clampi(r.x + r.w - 1, 0, W-1);
const int y1 = clampi(r.y + r.h - 1, 0, H-1);


std::vector<uint8_t> tmp((x1-x0+1)*(y1-y0+1)*4);
// Copy sub-rect
for(int y=y0; y<=y1; ++y){
const uint8_t* src = p + (y*W + x0)*4;
uint8_t* dst = tmp.data() + ((y-y0)*(x1-x0+1))*4;
std::copy(src, src + (x1-x0+1)*4, dst);
}


const int w = (x1-x0+1), h=(y1-y0+1);
// Horizontal pass
std::vector<uint8_t> horiz(w*h*4);
for(int y=0; y<h; ++y){
for(int x=0; x<w; ++x){
int rsum=0, gsum=0, bsum=0, asum=0, cnt=0;
for(int k=-rx; k<=rx; ++k){
int xx = clampi(x+k, 0, w-1);
const uint8_t* s = tmp.data() + ((y*w + xx)*4);
rsum+=s[0]; gsum+=s[1]; bsum+=s[2]; asum+=s[3]; cnt++;
}
uint8_t* d = horiz.data() + ((y*w + x)*4);
d[0]=uint8_t(rsum/cnt); d[1]=uint8_t(gsum/cnt);
d[2]=uint8_t(bsum/cnt); d[3]=uint8_t(asum/cnt);
}
}
// Vertical pass back into tmp
for(int y=0; y<h; ++y){
for(int x=0; x<w; ++x){
int rsum=0, gsum=0, bsum=0, asum=0, cnt=0;
for(int k=-ry; k<=ry; ++k){
int yy = clampi(y+k, 0, h-1);
const uint8_t* s = horiz.data() + ((yy*w + x)*4);
rsum+=s[0]; gsum+=s[1]; bsum+=s[2]; asum+=s[3]; cnt++;
}
uint8_t* d = tmp.data() + ((y*w + x)*4);
d[0]=uint8_t(rsum/cnt); d[1]=uint8_t(gsum/cnt);
d[2]=uint8_t(bsum/cnt); d[3]=uint8_t(asum/cnt);
}
}
// Blit back
for(int y=y0; y<=y1; ++y){
uint8_t* dst = p + (y*W + x0)*4;
const uint8_t* src = tmp.data() + ((y-y0)*w)*4;
std::copy(src, src + w*4, dst);
}