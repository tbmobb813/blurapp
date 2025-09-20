# Advanced Blur Architecture - MediaPipe + Native Pipeline

## Overview

Evolution from current Dart-based MVP to high-performance native pipeline with MediaPipe segmentation.

## Current vs. Future Architecture

### **Current (MVP - Working)**

```
[Image Picker] → [Dart BlurPipeline] → [Full Image Blur] → [Export]
                      ↓
                 Memory-optimized
                 3 blur types
                 Manual selection
```

### **Future (Advanced - Proposed)**

```
[Image Input] → [MediaPipe Segmentation] → [Mask Post-Process] → [Smart Blur] → [Composite] → [Export]
                        ↓                        ↓                    ↓            ↓
                  Person/Background         Dilate/Erode         Background      Alpha
                     Mask                  Edge Smooth          Only Blur      Composite
```

## Implementation Phases

### Phase 1: MediaPipe Integration

**Goal**: Replace manual AutoDetectService with automatic segmentation

**Native Layer (Android)**:

```cpp
// blurcore/segmentation/MediaPipeSegmenter.cpp
class MediaPipeSegmenter {
private:
    mediapipe::TaskRunner task_runner_;
    std::unique_ptr<mediapipe::tasks::vision::ImageSegmenter> segmenter_;
    
public:
    bool Initialize(const std::string& model_path);
    std::vector<uint8_t> SegmentImage(const cv::Mat& input_image);
    void Cleanup();
};

// JNI Bridge
JNIEXPORT jbyteArray JNICALL
Java_com_example_blurapp_BlurCore_segmentImage(
    JNIEnv* env, jobject, jbyteArray image_bytes) {
    // Convert Java bytes → cv::Mat
    // Run MediaPipe segmentation
    // Return mask as byte array
}
```

**Dart Integration**:

```dart
class AdvancedAutoDetectService extends AutoDetectService {
  static const _channel = MethodChannel('blur_core/segmentation');
  
  @override
  Future<Uint8List?> detectSegmentation(Uint8List imageBytes) async {
    if (_useNativeSegmentation) {
      try {
        final result = await _channel.invokeMethod<Uint8List>(
          'segmentImage',
          {'imageBytes': imageBytes}
        );
        return result;
      } catch (e) {
        // Fallback to manual mode
        return super.detectSegmentation(imageBytes);
      }
    }
    return super.detectSegmentation(imageBytes);
  }
}
```

### Phase 2: Native Blur Pipeline

**Goal**: GPU-accelerated blur operations

**Native Implementation**:

```cpp
// blurcore/effects/NativeBlur.cpp
class NativeBlur {
public:
    enum BlurType { GAUSSIAN, BOX, MOTION };
    
    static cv::Mat ApplyGaussianBlur(
        const cv::Mat& input, 
        double sigma,
        bool use_gpu = true
    );
    
    static cv::Mat ApplySelectiveBlur(
        const cv::Mat& original,
        const cv::Mat& mask,
        double blur_strength
    );
};

// GPU Shader (Metal/Vulkan fallback)
class GPUBlur {
    // Metal Performance Shaders on iOS
    // Vulkan compute on Android
    // OpenGL ES fallback
};
```

### Phase 3: Advanced Mask Processing

**Goal**: Professional-quality edge handling

```cpp
// blurcore/mask/MaskProcessor.cpp
class MaskProcessor {
public:
    static cv::Mat SmoothMaskEdges(
        const cv::Mat& mask,
        int feather_radius = 5
    );
    
    static cv::Mat RefineMaskEdges(
        const cv::Mat& original_image,
        const cv::Mat& initial_mask,
        double edge_threshold = 0.1
    );
    
    static cv::Mat ApplyMorphology(
        const cv::Mat& mask,
        int dilate_size = 3,
        int erode_size = 2
    );
};
```

### Phase 4: Smart Compositing

**Goal**: Intelligent foreground/background blending

```cpp
// blurcore/composite/SmartComposite.cpp
class SmartComposite {
public:
    static cv::Mat CompositeWithMask(
        const cv::Mat& foreground,
        const cv::Mat& background,
        const cv::Mat& mask,
        double feather_strength = 0.5
    );
    
    static cv::Mat AdaptiveComposite(
        const cv::Mat& original,
        const cv::Mat& blurred,
        const cv::Mat& mask,
        const CompositeSettings& settings
    );
};

struct CompositeSettings {
    double edge_preservation = 0.8;
    double color_matching = 0.6;
    bool preserve_highlights = true;
    bool adaptive_feather = true;
};
```

### Phase 5: Performance Optimization

**Goal**: Real-time processing capabilities

```dart
// Quality profiles
enum ProcessingQuality {
  fast,     // 720p, σ=6-8, feather=3-5px
  balanced, // 1080p, σ=10-12, feather=6-8px  
  crisp     // 1440p, σ=14-18, feather=10-12px
}

class PerformanceProfiler {
  static ProcessingSettings getOptimalSettings(
    Size imageSize,
    ProcessingQuality quality,
    bool isRealTime
  ) {
    // Return optimized parameters based on device capabilities
  }
}
```

## Native File Structure

```
app/android/blurcore/
├── CMakeLists.txt
├── include/
│   ├── blur_core.h
│   ├── segmentation/
│   │   └── mediapipe_segmenter.h
│   ├── effects/
│   │   ├── native_blur.h
│   │   └── gpu_blur.h
│   ├── mask/
│   │   └── mask_processor.h
│   └── composite/
│       └── smart_composite.h
├── src/
│   ├── jni_bridge.cpp
│   ├── segmentation/
│   │   └── mediapipe_segmenter.cpp
│   ├── effects/
│   │   ├── native_blur.cpp
│   │   └── gpu_blur.cpp
│   ├── mask/
│   │   └── mask_processor.cpp
│   └── composite/
│       └── smart_composite.cpp
└── deps/
    ├── mediapipe/     # MediaPipe Tasks AAR
    ├── opencv/        # OpenCV Android SDK
    └── models/        # TFLite models
        ├── selfie_segmentation.tflite
        └── face_detection.tflite
```

## Dart Integration Layer

```dart
// lib/native/advanced_blur_bindings.dart
class AdvancedBlurBindings {
  static const _channel = MethodChannel('blur_core');
  
  static Future<Uint8List> processWithSegmentation(
    Uint8List imageBytes,
    ProcessingSettings settings
  ) async {
    return await _channel.invokeMethod('processAdvanced', {
      'imageBytes': imageBytes,
      'blurStrength': settings.blurStrength,
      'quality': settings.quality.index,
      'useGPU': settings.useGPU,
      'edgeFeather': settings.edgeFeather,
    });
  }
}

// Enhanced BlurPipeline
class AdvancedBlurPipeline extends BlurPipeline {
  static Future<Uint8List> applyIntelligentBlur(
    Uint8List imageBytes,
    BlurType type,
    int strength, {
    ProcessingQuality quality = ProcessingQuality.balanced,
    bool autoSegment = true,
    double edgeFeather = 0.5,
  }) async {
    if (autoSegment && await _isNativeAvailable()) {
      return AdvancedBlurBindings.processWithSegmentation(
        imageBytes,
        ProcessingSettings(
          blurStrength: strength,
          quality: quality,
          edgeFeather: edgeFeather,
        )
      );
    }
    
    // Fallback to current Dart implementation
    return BlurPipeline.applyBlur(imageBytes, type, strength);
  }
}
```

## Migration Strategy

### **Immediate (Keep Current MVP)**

- ✅ Current implementation stays as fallback
- ✅ All tests continue to pass
- ✅ Privacy-first operation maintained

### **Phase 1: Foundation (Week 1-2)**

- Set up MediaPipe dependencies
- Create basic JNI bridge
- Implement simple segmentation

### **Phase 2: Enhancement (Week 3-4)**

- Add native blur operations
- Integrate with existing UI
- Performance benchmarking

### **Phase 3: Polish (Week 5-6)**

- Advanced mask processing
- GPU optimization
- Real-time preview

## Benefits of This Architecture

1. **Performance**: GPU-accelerated blur + native segmentation
2. **Quality**: Professional-grade edge handling
3. **Flexibility**: Multiple quality profiles
4. **Compatibility**: Dart fallback always available
5. **Privacy**: All processing remains on-device

## Dependencies

**Android**:

- MediaPipe Tasks (Segmentation)
- OpenCV Android SDK  
- NDK 21+

**iOS**:

- MediaPipe iOS Framework
- Metal Performance Shaders
- Accelerate Framework

**Flutter**:

- Platform channels for native integration
- Existing image processing fallback

This architecture provides a clear path from your current working MVP to a professional-grade blur application while maintaining privacy and cross-platform compatibility.
