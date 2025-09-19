 #pragma once
#include <cstdint>


#ifdef __cplusplus
extern "C" {
#endif


typedef struct {
int x; // left
int y; // top
int w; // width
int h; // height
} BlurRect;


// mode: 0 = gaussian-ish box blur, 1 = pixelate
// strength: radius for blur, block size for pixelate (>=2)
// pixels: RGBA8888 contiguous buffer, row stride = width*4
// returns 0 on success
int blur_apply_regions(uint8_t* pixels, int width, int height,
const BlurRect* rects, int rect_count,
int mode, int strength);


#ifdef __cplusplus
}
#endif