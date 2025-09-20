package com.example.blurapp

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream

/**
 * BlurCorePlugin - Flutter platform channel for native blur operations
 * 
 * Phase 1: MediaPipe segmentation integration
 * Phase 2: OpenCV blur engine with GPU acceleration
 * This plugin provides the Flutter interface to the native BlurCore functionality
 */
class BlurCorePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private const val CHANNEL_NAME = "blur_core"
        private const val TAG = "BlurCorePlugin"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Initialize native library
        android.util.Log.i(TAG, "BlurCore plugin attached, library available: ${BlurCore.isAvailable()}")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // Phase 1: MediaPipe methods
            "getVersion" -> handleGetVersion(result)
            "isMediaPipeAvailable" -> handleIsMediaPipeAvailable(result)
            "initializeSegmentation" -> handleInitializeSegmentation(call, result)
            "segmentImage" -> handleSegmentImage(call, result)
            "processImageBasic" -> handleProcessImageBasic(call, result)
            "getProcessingCapabilities" -> handleGetProcessingCapabilities(result)
            "cleanup" -> handleCleanup(result)
            
            // Phase 2: OpenCV blur methods
            "isOpenCVAvailable" -> handleIsOpenCVAvailable(result)
            "isGPUAvailable" -> handleIsGPUAvailable(result)
            "applyAdvancedBlur" -> handleApplyAdvancedBlur(call, result)
            "applySelectiveBlur" -> handleApplySelectiveBlur(call, result)
            
            // Phase 3: Advanced mask processing methods
            "refineMask" -> handleRefineMask(call, result)
            "smoothMaskEdges" -> handleSmoothMaskEdges(call, result)
            "optimizeMask" -> handleOptimizeMask(call, result)
            "createFeatheredMask" -> handleCreateFeatheredMask(call, result)
            
            else -> result.notImplemented()
        }
    }

    private fun handleGetVersion(result: Result) {
        try {
            val version = BlurCore.getVersionInfo()
            result.success(version)
        } catch (e: Exception) {
            result.error("VERSION_ERROR", "Failed to get version: ${e.message}", null)
        }
    }

    private fun handleIsMediaPipeAvailable(result: Result) {
        try {
            val available = BlurCore.isSegmentationAvailable()
            result.success(available)
        } catch (e: Exception) {
            result.error("MEDIAPIPE_CHECK_ERROR", "Failed to check MediaPipe: ${e.message}", null)
        }
    }

    private fun handleInitializeSegmentation(call: MethodCall, result: Result) {
        try {
            val modelPath = call.argument<String>("modelPath")
            if (modelPath == null) {
                result.error("INVALID_ARGS", "Model path is required", null)
                return
            }

            // Phase 1: Initialize segmentation with model
            val success = BlurCore.initializeSegmentation(context, modelPath)
            result.success(success)
            
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Failed to initialize segmentation: ${e.message}", null)
        }
    }

    private fun handleSegmentImage(call: MethodCall, result: Result) {
        try {
            val imageBytes = call.argument<ByteArray>("imageBytes")
            if (imageBytes == null) {
                result.error("INVALID_ARGS", "Image bytes are required", null)
                return
            }

            // Convert bytes to bitmap
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                result.error("DECODE_ERROR", "Failed to decode image", null)
                return
            }

            // Perform segmentation
            val maskBytes = BlurCore.segmentBitmap(bitmap)
            
            if (maskBytes != null) {
                result.success(maskBytes)
            } else {
                // Return empty array to indicate segmentation not available/failed
                result.success(ByteArray(0))
            }
            
        } catch (e: Exception) {
            result.error("SEGMENT_ERROR", "Segmentation failed: ${e.message}", null)
        }
    }

    private fun handleProcessImageBasic(call: MethodCall, result: Result) {
        try {
            val imageBytes = call.argument<ByteArray>("imageBytes")
            val blurStrength = call.argument<Int>("blurStrength")
            
            if (imageBytes == null || blurStrength == null) {
                result.error("INVALID_ARGS", "Image bytes and blur strength are required", null)
                return
            }

            // Convert bytes to bitmap
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                result.error("DECODE_ERROR", "Failed to decode image", null)
                return
            }

            // Process image
            val processedBitmap = BlurCore.processImage(bitmap, blurStrength)
            
            if (processedBitmap != null) {
                // Convert back to bytes
                val outputStream = ByteArrayOutputStream()
                processedBitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                result.success(outputStream.toByteArray())
            } else {
                // Return original image if processing failed
                result.success(imageBytes)
            }
            
        } catch (e: Exception) {
            result.error("PROCESS_ERROR", "Image processing failed: ${e.message}", null)
        }
    }

    private fun handleGetProcessingCapabilities(result: Result) {
        try {
            val capabilities = mutableMapOf<String, Any>()
            
            // Check what's available
            capabilities["nativeAvailable"] = BlurCore.isAvailable()
            capabilities["segmentationAvailable"] = BlurCore.isSegmentationAvailable()
            capabilities["openCVAvailable"] = BlurCore.isOpenCVAvailable()
            capabilities["gpuAvailable"] = BlurCore.isGPUAvailable()
            capabilities["version"] = BlurCore.getVersionInfo()
            
            // Phase 2: Enhanced capabilities
            capabilities["supportedBlurTypes"] = listOf("gaussian", "box", "motion")
            capabilities["maxImageSize"] = 4096 // Increased with OpenCV
            capabilities["selectiveBlur"] = BlurCore.isOpenCVAvailable()
            capabilities["advancedBlur"] = BlurCore.isOpenCVAvailable()
            
            // Phase 3: Advanced mask processing capabilities
            capabilities["maskProcessing"] = BlurCore.isOpenCVAvailable()
            capabilities["supportedMorphOps"] = listOf("dilate", "erode", "opening", "closing", "gradient")
            capabilities["maskFeathering"] = BlurCore.isOpenCVAvailable()
            capabilities["connectedComponents"] = BlurCore.isOpenCVAvailable()
            
            result.success(capabilities)
            
        } catch (e: Exception) {
            result.error("CAPABILITIES_ERROR", "Failed to get capabilities: ${e.message}", null)
        }
    }
    
    // Phase 2: OpenCV blur method handlers
    
    private fun handleIsOpenCVAvailable(result: Result) {
        try {
            val available = BlurCore.isOpenCVAvailable()
            result.success(available)
        } catch (e: Exception) {
            result.error("OPENCV_CHECK_ERROR", "Failed to check OpenCV: ${e.message}", null)
        }
    }
    
    private fun handleIsGPUAvailable(result: Result) {
        try {
            val available = BlurCore.isGPUAvailable()
            result.success(available)
        } catch (e: Exception) {
            result.error("GPU_CHECK_ERROR", "Failed to check GPU: ${e.message}", null)
        }
    }
    
    private fun handleApplyAdvancedBlur(call: MethodCall, result: Result) {
        try {
            val imageBytes = call.argument<ByteArray>("imageBytes")
                ?: return result.error("INVALID_ARGS", "Missing imageBytes", null)
            
            val sigma = call.argument<Double>("sigma") ?: 2.0
            val blurType = call.argument<Int>("blurType") ?: 0
            
            // Convert bytes to bitmap
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: return result.error("DECODE_ERROR", "Failed to decode image", null)
            
            // Apply advanced blur
            val processedBitmap = BlurCore.applyAdvancedBlur(bitmap, sigma, blurType)
            
            if (processedBitmap != null) {
                // Convert back to bytes
                val outputStream = ByteArrayOutputStream()
                processedBitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                result.success(outputStream.toByteArray())
            } else {
                result.error("BLUR_ERROR", "Advanced blur failed", null)
            }
            
        } catch (e: Exception) {
            result.error("ADVANCED_BLUR_ERROR", "Advanced blur failed: ${e.message}", null)
        }
    }
    
    private fun handleApplySelectiveBlur(call: MethodCall, result: Result) {
        try {
            val imageBytes = call.argument<ByteArray>("imageBytes")
                ?: return result.error("INVALID_ARGS", "Missing imageBytes", null)
            
            val maskBytes = call.argument<ByteArray>("maskBytes")
                ?: return result.error("INVALID_ARGS", "Missing maskBytes", null)
            
            val foregroundSigma = call.argument<Double>("foregroundSigma") ?: 0.0
            val backgroundSigma = call.argument<Double>("backgroundSigma") ?: 5.0
            
            // Convert bytes to bitmap
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: return result.error("DECODE_ERROR", "Failed to decode image", null)
            
            // Apply selective blur
            val processedBitmap = BlurCore.applySelectiveBlur(
                bitmap, maskBytes, foregroundSigma, backgroundSigma
            )
            
            if (processedBitmap != null) {
                // Convert back to bytes
                val outputStream = ByteArrayOutputStream()
                processedBitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                result.success(outputStream.toByteArray())
            } else {
                result.error("SELECTIVE_BLUR_ERROR", "Selective blur failed", null)
            }
            
        } catch (e: Exception) {
            result.error("SELECTIVE_BLUR_ERROR", "Selective blur failed: ${e.message}", null)
        }
    }
    
    // ================================================================================
    // Phase 3: Advanced Mask Processing Method Handlers
    // ================================================================================
    
    private fun handleRefineMask(call: MethodCall, result: Result) {
        try {
            val maskBytes = call.argument<ByteArray>("maskBytes")
                ?: return result.error("INVALID_ARGS", "Missing maskBytes", null)
            
            val width = call.argument<Int>("width")
                ?: return result.error("INVALID_ARGS", "Missing width", null)
            
            val height = call.argument<Int>("height")
                ?: return result.error("INVALID_ARGS", "Missing height", null)
            
            val operation = call.argument<String>("operation") ?: "dilate"
            val kernelSize = call.argument<Int>("kernelSize") ?: 3
            
            // Refine mask using morphological operations
            val refinedMask = BlurCore.refineMask(maskBytes, width, height, operation, kernelSize)
            
            if (refinedMask != null) {
                result.success(refinedMask)
            } else {
                result.error("REFINE_MASK_ERROR", "Mask refinement failed", null)
            }
            
        } catch (e: Exception) {
            result.error("REFINE_MASK_ERROR", "Mask refinement failed: ${e.message}", null)
        }
    }
    
    private fun handleSmoothMaskEdges(call: MethodCall, result: Result) {
        try {
            val maskBytes = call.argument<ByteArray>("maskBytes")
                ?: return result.error("INVALID_ARGS", "Missing maskBytes", null)
            
            val width = call.argument<Int>("width")
                ?: return result.error("INVALID_ARGS", "Missing width", null)
            
            val height = call.argument<Int>("height")
                ?: return result.error("INVALID_ARGS", "Missing height", null)
            
            val blurSigma = call.argument<Double>("blurSigma") ?: 1.0
            
            // Smooth mask edges
            val smoothedMask = BlurCore.smoothMaskEdges(maskBytes, width, height, blurSigma)
            
            if (smoothedMask != null) {
                result.success(smoothedMask)
            } else {
                result.error("SMOOTH_MASK_ERROR", "Mask edge smoothing failed", null)
            }
            
        } catch (e: Exception) {
            result.error("SMOOTH_MASK_ERROR", "Mask edge smoothing failed: ${e.message}", null)
        }
    }
    
    private fun handleOptimizeMask(call: MethodCall, result: Result) {
        try {
            val maskBytes = call.argument<ByteArray>("maskBytes")
                ?: return result.error("INVALID_ARGS", "Missing maskBytes", null)
            
            val width = call.argument<Int>("width")
                ?: return result.error("INVALID_ARGS", "Missing width", null)
            
            val height = call.argument<Int>("height")
                ?: return result.error("INVALID_ARGS", "Missing height", null)
            
            val minArea = call.argument<Int>("minArea") ?: 100
            
            // Optimize mask using connected components
            val optimizedMask = BlurCore.optimizeMask(maskBytes, width, height, minArea)
            
            if (optimizedMask != null) {
                result.success(optimizedMask)
            } else {
                result.error("OPTIMIZE_MASK_ERROR", "Mask optimization failed", null)
            }
            
        } catch (e: Exception) {
            result.error("OPTIMIZE_MASK_ERROR", "Mask optimization failed: ${e.message}", null)
        }
    }
    
    private fun handleCreateFeatheredMask(call: MethodCall, result: Result) {
        try {
            val maskBytes = call.argument<ByteArray>("maskBytes")
                ?: return result.error("INVALID_ARGS", "Missing maskBytes", null)
            
            val width = call.argument<Int>("width")
                ?: return result.error("INVALID_ARGS", "Missing width", null)
            
            val height = call.argument<Int>("height")
                ?: return result.error("INVALID_ARGS", "Missing height", null)
            
            val featherRadius = call.argument<Int>("featherRadius") ?: 5
            
            // Create feathered mask
            val featheredMask = BlurCore.createFeatheredMask(maskBytes, width, height, featherRadius)
            
            if (featheredMask != null) {
                result.success(featheredMask)
            } else {
                result.error("FEATHER_MASK_ERROR", "Mask feathering failed", null)
            }
            
        } catch (e: Exception) {
            result.error("FEATHER_MASK_ERROR", "Mask feathering failed: ${e.message}", null)
        }
    }

    private fun handleCleanup(result: Result) {
        try {
            BlurCore.cleanup()
            result.success(true)
        } catch (e: Exception) {
            result.error("CLEANUP_ERROR", "Cleanup failed: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        
        // Cleanup native resources
        try {
            BlurCore.cleanup()
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error during plugin cleanup: ${e.message}")
        }
    }
}