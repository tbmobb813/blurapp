// Enhanced native blur core with MediaPipe foundation
// This extends the current stub to prepare for MediaPipe integration

#include <jni.h>
#include <android/log.h>
#include <vector>
#include <string>

#define LOG_TAG "BlurCore"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

// Current stub functionality
JNIEXPORT jstring JNICALL
Java_com_example_blurapp_BlurCore_getVersion(JNIEnv *env, jobject) {
    LOGI("BlurCore: getVersion called");
    return env->NewStringUTF("BlurCore v1.0.0 (stub)");
}

// Phase 1: Basic image processing foundation
JNIEXPORT jbyteArray JNICALL
Java_com_example_blurapp_BlurCore_processImageBasic(
    JNIEnv *env, jobject, jbyteArray input_bytes, jint blur_strength) {
    
    LOGI("BlurCore: Basic image processing called with strength %d", blur_strength);
    
    // For now, return input unchanged (Phase 1 preparation)
    jsize input_length = env->GetArrayLength(input_bytes);
    jbyte* input_data = env->GetByteArrayElements(input_bytes, nullptr);
    
    // Create output array (copy of input for now)
    jbyteArray result = env->NewByteArray(input_length);
    env->SetByteArrayRegion(result, 0, input_length, input_data);
    
    env->ReleaseByteArrayElements(input_bytes, input_data, JNI_ABORT);
    
    LOGI("BlurCore: Processed %d bytes", input_length);
    return result;
}

// Phase 1: Segmentation preparation (stub for MediaPipe)
JNIEXPORT jbyteArray JNICALL
Java_com_example_blurapp_BlurCore_segmentImage(
    JNIEnv *env, jobject, jbyteArray image_bytes) {
    
    LOGI("BlurCore: Segmentation requested (stub implementation)");
    
    // TODO Phase 1: MediaPipe segmentation will go here
    // For now, return empty array to indicate "not yet implemented"
    jbyteArray result = env->NewByteArray(0);
    
    LOGI("BlurCore: Segmentation stub completed");
    return result;
}

// Phase 2: Advanced blur with mask (preparation)
JNIEXPORT jbyteArray JNICALL
Java_com_example_blurapp_BlurCore_applySelectiveBlur(
    JNIEnv *env, jobject, 
    jbyteArray image_bytes, 
    jbyteArray mask_bytes, 
    jfloat blur_strength) {
    
    LOGI("BlurCore: Selective blur requested with strength %.2f", blur_strength);
    
    // TODO Phase 2: Native selective blur implementation
    // For now, return original image
    jsize input_length = env->GetArrayLength(image_bytes);
    jbyte* input_data = env->GetByteArrayElements(image_bytes, nullptr);
    
    jbyteArray result = env->NewByteArray(input_length);
    env->SetByteArrayRegion(result, 0, input_length, input_data);
    
    env->ReleaseByteArrayElements(image_bytes, input_data, JNI_ABORT);
    
    LOGI("BlurCore: Selective blur stub completed");
    return result;
}

// Utility: Check native capabilities
JNIEXPORT jboolean JNICALL
Java_com_example_blurapp_BlurCore_isMediaPipeAvailable(JNIEnv *env, jobject) {
    LOGI("BlurCore: Checking MediaPipe availability");
    
    // TODO Phase 1: Actual MediaPipe availability check
    // For now, return false (use Dart fallback)
    return JNI_FALSE;
}

// Utility: Get supported blur types
JNIEXPORT jintArray JNICALL
Java_com_example_blurapp_BlurCore_getSupportedBlurTypes(JNIEnv *env, jobject) {
    LOGI("BlurCore: Getting supported blur types");
    
    // Return basic blur types for now
    // 0 = Gaussian, 1 = Box, 2 = Motion (future)
    std::vector<int> supported_types = {0}; // Only Gaussian for Phase 1
    
    jintArray result = env->NewIntArray(supported_types.size());
    env->SetIntArrayRegion(result, 0, supported_types.size(), supported_types.data());
    
    return result;
}

// Performance: Get processing capabilities
JNIEXPORT jobject JNICALL
Java_com_example_blurapp_BlurCore_getProcessingCapabilities(JNIEnv *env, jobject) {
    LOGI("BlurCore: Getting processing capabilities");
    
    // TODO: Return device capabilities (GPU, memory, etc.)
    // For now, return null to indicate "use Dart fallback"
    return nullptr;
}

} // extern "C"