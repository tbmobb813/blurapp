import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../features/editor/blur_pipeline.dart';

/// Native blur core bindings for enhanced processing
///
/// Phase 1: MediaPipe segmentation foundation
/// Phase 2: OpenCV blur engine with GPU acceleration
/// This class provides the interface to the native C++ blur implementation
/// while maintaining fallback compatibility with the existing Dart pipeline.
class NativeBlurBindings {
  static const _channel = MethodChannel('blur_core');

  // Cache native availability to avoid repeated checks
  static bool? _isNativeAvailable;
  static List<int>? _supportedBlurTypes;

  /// Check if native processing is available on this device
  static Future<bool> isNativeAvailable() async {
    if (_isNativeAvailable != null) {
      return _isNativeAvailable!;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isMediaPipeAvailable');
      _isNativeAvailable = result ?? false;

      if (_isNativeAvailable!) {
        debugPrint('NativeBlurBindings: Native processing available');
      } else {
        debugPrint('NativeBlurBindings: Using Dart fallback');
      }

      return _isNativeAvailable!;
    } catch (e) {
      debugPrint('NativeBlurBindings error checking availability: $e');
      _isNativeAvailable = false;
      return false;
    }
  }

  /// Get the version of the native blur core
  static Future<String> getVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getVersion');
      return result ?? 'Unknown version';
    } catch (e) {
      debugPrint('NativeBlurBindings error getting version: $e');
      return 'Error: $e';
    }
  }

  /// Get supported blur types from native implementation
  static Future<List<int>> getSupportedBlurTypes() async {
    if (_supportedBlurTypes != null) {
      return _supportedBlurTypes!;
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getSupportedBlurTypes');
      _supportedBlurTypes = result?.cast<int>() ?? [];
      return _supportedBlurTypes!;
    } catch (e) {
      debugPrint('NativeBlurBindings error getting blur types: $e');
      _supportedBlurTypes = [];
      return [];
    }
  }

  /// Initialize MediaPipe segmentation (Phase 1)
  static Future<bool> initializeSegmentation({String modelPath = 'assets/models/selfie_segmentation.tflite'}) async {
    try {
      final result = await _channel.invokeMethod<bool>('initializeSegmentation', {'modelPath': modelPath});

      final success = result ?? false;
      debugPrint('NativeBlurBindings: Segmentation initialization ${success ? "succeeded" : "failed"}');
      return success;
    } catch (e) {
      debugPrint('NativeBlurBindings error initializing segmentation: $e');
      return false;
    }
  }

  /// Apply basic native blur (Phase 1 - preparation for MediaPipe)
  static Future<Uint8List?> processImageBasic(Uint8List imageBytes, int blurStrength) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('processImageBasic', {
        'imageBytes': imageBytes,
        'blurStrength': blurStrength,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in basic processing: $e');
      return null;
    }
  }

  /// Generate segmentation mask using MediaPipe (Phase 1 target)
  static Future<Uint8List?> segmentImage(Uint8List imageBytes) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('segmentImage', {'imageBytes': imageBytes});

      // Empty result means segmentation not yet implemented
      if (result == null || result.isEmpty) {
        return null;
      }

      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in segmentation: $e');
      return null;
    }
  }

  /// Phase 2: Check if OpenCV is available
  static Future<bool> isOpenCVAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOpenCVAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBlurBindings error checking OpenCV: $e');
      return false;
    }
  }

  /// Phase 2: Check if GPU acceleration is available
  static Future<bool> isGPUAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isGPUAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeBlurBindings error checking GPU: $e');
      return false;
    }
  }

  /// Phase 2: Apply advanced blur with detailed parameters
  static Future<Uint8List?> applyAdvancedBlur(
    Uint8List imageBytes, {
    required double sigma,
    int blurType = 0, // 0: Gaussian, 1: Box, 2: Motion
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('applyAdvancedBlur', {
        'imageBytes': imageBytes,
        'sigma': sigma,
        'blurType': blurType,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in advanced blur: $e');
      return null;
    }
  }

  /// Phase 2: Apply selective blur using mask with enhanced parameters
  static Future<Uint8List?> applySelectiveBlur(
    Uint8List imageBytes,
    Uint8List maskBytes, {
    double foregroundSigma = 0.0,
    double backgroundSigma = 5.0,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('applySelectiveBlur', {
        'imageBytes': imageBytes,
        'maskBytes': maskBytes,
        'foregroundSigma': foregroundSigma,
        'backgroundSigma': backgroundSigma,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in selective blur: $e');
      return null;
    }
  }

  /// Apply selective blur using mask (Legacy Phase 1 compatibility)
  static Future<Uint8List?> applySelectiveBlurLegacy(
    Uint8List imageBytes,
    Uint8List maskBytes,
    double blurStrength,
  ) async {
    // Convert legacy blur strength to sigma values
    final sigma = blurStrength * 0.1; // Simple conversion

    return applySelectiveBlur(imageBytes, maskBytes, foregroundSigma: 0.0, backgroundSigma: sigma);
  }

  // ================================================================================
  // Phase 3: Advanced Mask Processing Methods
  // ================================================================================

  /// Phase 3: Refine mask using morphological operations
  static Future<Uint8List?> refineMask(
    Uint8List maskBytes,
    int width,
    int height, {
    String operation = 'dilate', // 'dilate', 'erode', 'opening', 'closing', 'gradient'
    int kernelSize = 3,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('refineMask', {
        'maskBytes': maskBytes,
        'width': width,
        'height': height,
        'operation': operation,
        'kernelSize': kernelSize,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in mask refinement: $e');
      return null;
    }
  }

  /// Phase 3: Smooth mask edges using Gaussian blur and distance transforms
  static Future<Uint8List?> smoothMaskEdges(
    Uint8List maskBytes,
    int width,
    int height, {
    double blurSigma = 1.0,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('smoothMaskEdges', {
        'maskBytes': maskBytes,
        'width': width,
        'height': height,
        'blurSigma': blurSigma,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in mask edge smoothing: $e');
      return null;
    }
  }

  /// Phase 3: Optimize mask using connected components analysis
  static Future<Uint8List?> optimizeMask(Uint8List maskBytes, int width, int height, {int minArea = 100}) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('optimizeMask', {
        'maskBytes': maskBytes,
        'width': width,
        'height': height,
        'minArea': minArea,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in mask optimization: $e');
      return null;
    }
  }

  /// Phase 3: Create feathered mask using dual distance transforms
  static Future<Uint8List?> createFeatheredMask(
    Uint8List maskBytes,
    int width,
    int height, {
    int featherRadius = 5,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('createFeatheredMask', {
        'maskBytes': maskBytes,
        'width': width,
        'height': height,
        'featherRadius': featherRadius,
      });
      return result;
    } catch (e) {
      debugPrint('NativeBlurBindings error in mask feathering: $e');
      return null;
    }
  }

  /// Phase 3: Apply complete mask processing pipeline
  static Future<Uint8List?> processAdvancedMask(
    Uint8List maskBytes,
    int width,
    int height, {
    String? morphOperation,
    int morphKernelSize = 3,
    double edgeBlurSigma = 1.0,
    int? minArea,
    int? featherRadius,
  }) async {
    Uint8List? processedMask = maskBytes;

    try {
      // Step 1: Apply morphological operations if specified
      if (morphOperation != null) {
        processedMask = await refineMask(
          processedMask,
          width,
          height,
          operation: morphOperation,
          kernelSize: morphKernelSize,
        );
        if (processedMask == null) return null;
        debugPrint('NativeBlurBindings: Applied morphological operation: $morphOperation');
      }

      // Step 2: Optimize mask with connected components if specified
      if (minArea != null) {
        processedMask = await optimizeMask(processedMask, width, height, minArea: minArea);
        if (processedMask == null) return null;
        debugPrint('NativeBlurBindings: Optimized mask with min area: $minArea');
      }

      // Step 3: Smooth edges
      processedMask = await smoothMaskEdges(processedMask, width, height, blurSigma: edgeBlurSigma);
      if (processedMask == null) return null;
      debugPrint('NativeBlurBindings: Smoothed mask edges with sigma: $edgeBlurSigma');

      // Step 4: Apply feathering if specified
      if (featherRadius != null) {
        processedMask = await createFeatheredMask(processedMask, width, height, featherRadius: featherRadius);
        if (processedMask == null) return null;
        debugPrint('NativeBlurBindings: Applied feathering with radius: $featherRadius');
      }

      return processedMask;
    } catch (e) {
      debugPrint('NativeBlurBindings error in advanced mask processing: $e');
      return null;
    }
  }

  /// Get device processing capabilities
  static Future<Map<String, dynamic>?> getProcessingCapabilities() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getProcessingCapabilities');
      return result?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('NativeBlurBindings error getting capabilities: $e');
      return null;
    }
  }
}

/// Enhanced blur pipeline that intelligently uses native or Dart processing
class HybridBlurPipeline {
  /// Process image with best available method (native or Dart fallback)
  static Future<Uint8List> processImage(
    Uint8List imageBytes,
    BlurType type,
    int strength, {
    bool preferNative = true,
    bool isPreview = false,
  }) async {
    // Check if native processing should be attempted
    if (preferNative && await NativeBlurBindings.isNativeAvailable()) {
      final nativeResult = await NativeBlurBindings.processImageBasic(imageBytes, strength);

      if (nativeResult != null) {
        debugPrint('HybridBlurPipeline: Used native processing');
        return nativeResult;
      }
    }

    // Fallback to existing Dart implementation
    debugPrint('HybridBlurPipeline: Using Dart fallback');
    return BlurPipeline.applyBlur(imageBytes, type, strength, isPreview: isPreview);
  }

  /// Process with automatic segmentation if available
  static Future<Uint8List> processWithAutoSegmentation(
    Uint8List imageBytes,
    int blurStrength, {
    bool isPreview = false,
  }) async {
    // Try automatic segmentation first
    final mask = await NativeBlurBindings.segmentImage(imageBytes);

    if (mask != null && mask.isNotEmpty) {
      // Use selective blur with detected mask
      final result = await NativeBlurBindings.applySelectiveBlurLegacy(imageBytes, mask, blurStrength.toDouble());

      if (result != null) {
        debugPrint('HybridBlurPipeline: Used automatic segmentation');
        return result;
      }
    }

    // Fallback to manual mode (existing AutoDetectService)
    debugPrint('HybridBlurPipeline: Fallback to manual selection');
    return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, blurStrength, isPreview: isPreview);
  }

  /// Get processing mode info for UI display
  static Future<ProcessingModeInfo> getProcessingModeInfo() async {
    final nativeAvailable = await NativeBlurBindings.isNativeAvailable();
    final version = await NativeBlurBindings.getVersion();
    final supportedTypes = await NativeBlurBindings.getSupportedBlurTypes();
    final capabilities = await NativeBlurBindings.getProcessingCapabilities();

    return ProcessingModeInfo(
      hasNativeSupport: nativeAvailable,
      nativeVersion: version,
      supportedBlurTypes: supportedTypes,
      capabilities: capabilities ?? {},
    );
  }
}

/// Information about available processing modes
class ProcessingModeInfo {
  final bool hasNativeSupport;
  final String nativeVersion;
  final List<int> supportedBlurTypes;
  final Map<String, dynamic> capabilities;

  const ProcessingModeInfo({
    required this.hasNativeSupport,
    required this.nativeVersion,
    required this.supportedBlurTypes,
    required this.capabilities,
  });

  bool get hasAutoSegmentation => hasNativeSupport && capabilities.containsKey('segmentation');

  bool get hasGpuAcceleration => hasNativeSupport && capabilities['gpu'] == true;

  // Phase 3: Advanced mask processing capabilities
  bool get hasMaskProcessing => hasNativeSupport && capabilities['maskProcessing'] == true;

  bool get hasFeathering => hasNativeSupport && capabilities['maskFeathering'] == true;

  bool get hasConnectedComponents => hasNativeSupport && capabilities['connectedComponents'] == true;

  List<String> get supportedMorphOps => (capabilities['supportedMorphOps'] as List<dynamic>?)?.cast<String>() ?? [];

  String get displayMode {
    if (hasNativeSupport) {
      if (hasMaskProcessing && hasAutoSegmentation) {
        return 'AI-Enhanced Pro';
      } else if (hasAutoSegmentation) {
        return 'AI-Powered';
      } else if (hasMaskProcessing) {
        return 'Advanced Native';
      } else {
        return 'Native-Accelerated';
      }
    }
    return 'Privacy-First (Dart)';
  }
}
