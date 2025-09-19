#include <algorithm>
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
}


// Pixelate by averaging blocks inside rect
static void pixelateRGBA(uint8_t* p, int W, int H, int block, const BlurRect& r){
block = std::max(2, block);
const int x0 = clampi(r.x, 0, W-1);
const int y0 = clampi(r.y, 0, H-1);
const int x1 = clampi(r.x + r.w, 0, W);
const int y1 = clampi(r.y + r.h, 0, H);


for(int by=y0; by<y1; by+=block){
for(int bx=x0; bx<x1; bx+=block){
int rsum=0, gsum=0, bsum=0, asum=0, cnt=0;
int ex = std::min(bx+block, x1);
int ey = std::min(by+block, y1);
for(int y=by; y<ey; ++y){
for(int x=bx; x<ex; ++x){
uint8_t* px = p + (y*W + x)*4;
rsum+=px[0]; gsum+=px[1]; bsum+=px[2]; asum+=px[3]; cnt++;
}
}
uint8_t r8=uint8_t(rsum/cnt), g8=uint8_t(gsum/cnt), b8=uint8_t(bsum/cnt), a8=uint8_t(asum/cnt);
for(int y=by; y<ey; ++y){
for(int x=bx; x<ex; ++x){
uint8_t* px = p + (y*W + x)*4;
px[0]=r8; px[1]=g8; px[2]=b8; px[3]=a8;
}
}
}
}
}


int blur_apply_regions(uint8_t* pixels, int width, int height,
const BlurRect* rects, int rect_count,
int mode, int strength){
if(!pixels || width<=0 || height<=0 || !rects || rect_count<=0) return -1;
for(int i=0;i<rect_count;++i){
if(mode==0){
boxBlurRGBA(pixels, width, height, strength, strength, rects[i]);
} else {
pixelateRGBA(pixels, width, height, strength, rects[i]);
}
}
return 0;
}