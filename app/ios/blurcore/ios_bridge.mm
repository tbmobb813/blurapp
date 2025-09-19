#import <Foundation/Foundation.h>
#import "../../native/include/blur.h"
extern "C" int ios_blur_apply(unsigned char* pixels, int w, int h, int* rects, int nRects, int mode, int strength){
BlurRect* rs = (BlurRect*)malloc(sizeof(BlurRect)*nRects);
for(int i=0;i<nRects;i++){
rs[i].x=rects[i*4+0]; rs[i].y=rects[i*4+1]; rs[i].w=rects[i*4+2]; rs[i].h=rects[i*4+3];
}
int r = blur_apply_regions(pixels, w, h, rs, nRects, mode, strength);
free(rs); return r;
}