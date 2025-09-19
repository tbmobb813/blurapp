#include <jni.h>
#include <cstdint>
#include "../../native/include/blur.h"


extern "C" JNIEXPORT jint JNICALL
Java_com_blurapp_blurcore_BlurBridge_apply(
JNIEnv* env, jobject /*thiz*/, jlong bufferPtr, jint w, jint h,
jintArray rects, jint mode, jint strength){
// rects packed as [x,y,w,h]*N
jsize len = env->GetArrayLength(rects);
jboolean isCopy=false;
jint* arr = env->GetIntArrayElements(rects, &isCopy);
int n = len/4; std::vector<BlurRect> rs(n);
for(int i=0;i<n;++i){ rs[i]={arr[i*4+0],arr[i*4+1],arr[i*4+2],arr[i*4+3]}; }
env->ReleaseIntArrayElements(rects, arr, 0);
return blur_apply_regions(reinterpret_cast<uint8_t*>(bufferPtr), w, h, rs.data(), n, mode, strength);
}