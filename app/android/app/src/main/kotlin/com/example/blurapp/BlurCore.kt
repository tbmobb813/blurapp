package com.example.blurapp

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import java.io.ByteArrayOutputStream

/**
 * BlurCore native library interface
 * 
 * Phase 1: MediaPipe segmentation foundation
 * Phase 2: OpenCV blur engine with GPU acceleration
 * This class provides the bridge between Flutter/Dart and the native C++ implementation
 */
class BlurCore private constructor() {
    
    companion object {
        private const val TAG = "BlurCore"
        private var isLibraryLoaded = false
        private var isInitialized = false
        
        // Load native library
        init {
            try {
                System.loadLibrary("blurcore")
                isLibraryLoaded = true
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library: ${e.message}")
                isLibraryLoaded = false
            }
        }
        
        @JvmStatic
        fun isAvailable(): Boolean = isLibraryLoaded
        
        @JvmStatic
        fun getVersionInfo(): String {
            return if (isLibraryLoaded) {
                try {
                    nativeGetVersion()
                } catch (e: Exception) {
                    "BlurCore: Error getting version - ${e.message}"
                }
            } else {
                "BlurCore: Native library not loaded"
            }
        }
        
        /**
         * Initialize MediaPipe segmentation
         * Phase 1: Sets up the segmentation model
         */
        @JvmStatic
        fun initializeSegmentation(context: Context, modelPath: String): Boolean {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot initialize - native library not loaded")
                return false
            }
            
            try {
                // For Phase 1, we'll prepare the model path
                val fullPath = if (modelPath.startsWith("assets/")) {
                    // Extract asset to cache directory for native access
                    extractAssetToCache(context, modelPath)
                } else {
                    modelPath
                }
                
                val result = nativeInitializeSegmentation(fullPath)
                isInitialized = result
                
                Log.i(TAG, "Segmentation initialization: ${if (result) "success" else "failed"}")
                return result
                
            } catch (e: Exception) {
                Log.e(TAG, "Error initializing segmentation: ${e.message}")
                return false
            }
        }
        
        /**
         * Extract asset file to cache directory for native access
         */
        private fun extractAssetToCache(context: Context, assetPath: String): String {
            val fileName = assetPath.substringAfterLast("/")
            val cacheFile = java.io.File(context.cacheDir, fileName)
            
            if (!cacheFile.exists()) {
                try {
                    context.assets.open(assetPath).use { input ->
                        cacheFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    Log.i(TAG, "Extracted asset $assetPath to ${cacheFile.absolutePath}")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to extract asset $assetPath: ${e.message}")
                    return assetPath // Return original path as fallback
                }
            }
            
            return cacheFile.absolutePath
        }
        
        /**
         * Check if MediaPipe segmentation is available
         */
        @JvmStatic
        fun isSegmentationAvailable(): Boolean {
            return if (isLibraryLoaded) {
                try {
                    nativeIsMediaPipeAvailable()
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking MediaPipe availability: ${e.message}")
                    false
                }
            } else {
                false
            }
        }
        
        /**
         * Perform image segmentation
         * Phase 1: Returns segmentation mask for background/foreground separation
         */
        @JvmStatic
        fun segmentBitmap(bitmap: Bitmap): ByteArray? {
            if (!isLibraryLoaded || !isInitialized) {
                Log.w(TAG, "Cannot segment - library not loaded or not initialized")
                return null
            }
            
            try {
                // Convert bitmap to byte array
                val imageBytes = bitmapToByteArray(bitmap)
                
                // Call native segmentation
                val result = nativeSegmentImage(imageBytes, bitmap.width, bitmap.height)
                
                Log.d(TAG, "Segmentation completed, result size: ${result.size}")
                return if (result.isNotEmpty()) result else null
                
            } catch (e: Exception) {
                Log.e(TAG, "Error during segmentation: ${e.message}")
                return null
            }
        }
        
        /**
         * Apply basic image processing
         * Phase 2: Enhanced with OpenCV blur operations
         */
        @JvmStatic
        fun processImage(bitmap: Bitmap, blurStrength: Int): Bitmap? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot process - library not loaded")
                return null
            }
            
            try {
                val imageBytes = bitmapToByteArray(bitmap)
                val processedBytes = nativeProcessImageBasic(imageBytes, blurStrength)
                
                return if (processedBytes.isNotEmpty()) {
                    byteArrayToBitmap(processedBytes)
                } else {
                    null
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error processing image: ${e.message}")
                return null
            }
        }
        
        /**
         * Phase 2: Apply advanced blur with detailed parameters
         */
        @JvmStatic
        fun applyAdvancedBlur(bitmap: Bitmap, sigma: Double, blurType: Int): Bitmap? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot apply advanced blur - library not loaded")
                return null
            }
            
            try {
                val imageBytes = bitmapToByteArray(bitmap)
                val channels = if (bitmap.config == Bitmap.Config.ARGB_8888) 4 else 3
                
                val processedBytes = nativeApplyAdvancedBlur(
                    imageBytes, bitmap.width, bitmap.height, channels, sigma, blurType
                )
                
                return if (processedBytes.isNotEmpty()) {
                    byteArrayToBitmap(processedBytes)
                } else {
                    null
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error applying advanced blur: ${e.message}")
                return null
            }
        }
        
        /**
         * Phase 2: Apply selective blur using segmentation mask
         */
        @JvmStatic
        fun applySelectiveBlur(bitmap: Bitmap, mask: ByteArray, 
                             foregroundSigma: Double, backgroundSigma: Double): Bitmap? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot apply selective blur - library not loaded")
                return null
            }
            
            try {
                val imageBytes = bitmapToByteArray(bitmap)
                val channels = if (bitmap.config == Bitmap.Config.ARGB_8888) 4 else 3
                
                val processedBytes = nativeApplySelectiveBlur(
                    imageBytes, mask, bitmap.width, bitmap.height, channels,
                    foregroundSigma, backgroundSigma
                )
                
                return if (processedBytes.isNotEmpty()) {
                    byteArrayToBitmap(processedBytes)
                } else {
                    null
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error applying selective blur: ${e.message}")
                return null
            }
        }
        
        /**
         * Phase 2: Check if OpenCV is available
         */
        @JvmStatic
        fun isOpenCVAvailable(): Boolean {
            return if (isLibraryLoaded) {
                try {
                    nativeIsOpenCVAvailable()
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking OpenCV availability: ${e.message}")
                    false
                }
            } else {
                false
            }
        }
        
        /**
         * Phase 2: Check if GPU acceleration is available
         */
        @JvmStatic
        fun isGPUAvailable(): Boolean {
            return if (isLibraryLoaded) {
                try {
                    nativeIsGPUAvailable()
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking GPU availability: ${e.message}")
                    false
                }
            } else {
                false
            }
        }
        
        // ================================================================================
        // Phase 3: Advanced Mask Processing Methods
        // ================================================================================
        
        /**
         * Phase 3: Refine mask using morphological operations
         * @param maskBytes Raw mask data as byte array
         * @param width Image width
         * @param height Image height
         * @param operation Morphological operation type ("dilate", "erode", "opening", "closing", "gradient")
         * @param kernelSize Morphological kernel size
         */
        @JvmStatic
        fun refineMask(maskBytes: ByteArray, width: Int, height: Int, 
                      operation: String, kernelSize: Int): ByteArray? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot refine mask - library not loaded")
                return null
            }
            
            try {
                val result = nativeRefineMask(maskBytes, width, height, operation, kernelSize)
                
                Log.d(TAG, "Mask refinement completed, result size: ${result.size}")
                return if (result.isNotEmpty()) result else null
                
            } catch (e: Exception) {
                Log.e(TAG, "Error refining mask: ${e.message}")
                return null
            }
        }
        
        /**
         * Phase 3: Smooth mask edges using Gaussian blur and distance transforms
         * @param maskBytes Raw mask data as byte array
         * @param width Image width
         * @param height Image height
         * @param blurSigma Gaussian blur sigma for edge smoothing
         */
        @JvmStatic
        fun smoothMaskEdges(maskBytes: ByteArray, width: Int, height: Int, 
                           blurSigma: Double): ByteArray? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot smooth mask edges - library not loaded")
                return null
            }
            
            try {
                val result = nativeSmoothMaskEdges(maskBytes, width, height, blurSigma)
                
                Log.d(TAG, "Mask edge smoothing completed, result size: ${result.size}")
                return if (result.isNotEmpty()) result else null
                
            } catch (e: Exception) {
                Log.e(TAG, "Error smoothing mask edges: ${e.message}")
                return null
            }
        }
        
        /**
         * Phase 3: Optimize mask using connected components analysis
         * @param maskBytes Raw mask data as byte array
         * @param width Image width
         * @param height Image height
         * @param minArea Minimum area for connected components (pixels)
         */
        @JvmStatic
        fun optimizeMask(maskBytes: ByteArray, width: Int, height: Int, 
                        minArea: Int): ByteArray? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot optimize mask - library not loaded")
                return null
            }
            
            try {
                val result = nativeOptimizeMask(maskBytes, width, height, minArea)
                
                Log.d(TAG, "Mask optimization completed, result size: ${result.size}")
                return if (result.isNotEmpty()) result else null
                
            } catch (e: Exception) {
                Log.e(TAG, "Error optimizing mask: ${e.message}")
                return null
            }
        }
        
        /**
         * Phase 3: Create feathered mask using dual distance transforms
         * @param maskBytes Raw mask data as byte array
         * @param width Image width
         * @param height Image height
         * @param featherRadius Feathering radius in pixels
         */
        @JvmStatic
        fun createFeatheredMask(maskBytes: ByteArray, width: Int, height: Int, 
                               featherRadius: Int): ByteArray? {
            if (!isLibraryLoaded) {
                Log.w(TAG, "Cannot create feathered mask - library not loaded")
                return null
            }
            
            try {
                val result = nativeCreateFeatheredMask(maskBytes, width, height, featherRadius)
                
                Log.d(TAG, "Mask feathering completed, result size: ${result.size}")
                return if (result.isNotEmpty()) result else null
                
            } catch (e: Exception) {
                Log.e(TAG, "Error creating feathered mask: ${e.message}")
                return null
            }
        }
        
        /**
         * Clean up native resources
         */
        @JvmStatic
        fun cleanup() {
            if (isLibraryLoaded) {
                try {
                    nativeCleanup()
                    isInitialized = false
                    Log.i(TAG, "Cleanup completed")
                } catch (e: Exception) {
                    Log.e(TAG, "Error during cleanup: ${e.message}")
                }
            }
        }
        
        // Utility functions
        private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            return stream.toByteArray()
        }
        
        private fun byteArrayToBitmap(bytes: ByteArray): Bitmap? {
            return try {
                android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            } catch (e: Exception) {
                Log.e(TAG, "Error converting bytes to bitmap: ${e.message}")
                null
            }
        }
        
        // Native function declarations
        // Phase 1: MediaPipe functions
        @JvmStatic
        private external fun nativeGetVersion(): String
        @JvmStatic
        private external fun nativeIsMediaPipeAvailable(): Boolean
        @JvmStatic
        private external fun nativeInitializeSegmentation(modelPath: String): Boolean
        @JvmStatic
        private external fun nativeSegmentImage(imageBytes: ByteArray, width: Int, height: Int): ByteArray
        @JvmStatic
        private external fun nativeProcessImageBasic(imageBytes: ByteArray, blurStrength: Int): ByteArray
        
        // Phase 2: OpenCV blur functions
        @JvmStatic
        private external fun nativeApplyAdvancedBlur(imageBytes: ByteArray, width: Int, height: Int, 
                                                    channels: Int, sigma: Double, blurType: Int): ByteArray
        @JvmStatic
        private external fun nativeApplySelectiveBlur(imageBytes: ByteArray, maskBytes: ByteArray,
                                                     width: Int, height: Int, channels: Int,
                                                     foregroundSigma: Double, backgroundSigma: Double): ByteArray
        @JvmStatic
        private external fun nativeIsOpenCVAvailable(): Boolean
        @JvmStatic
        private external fun nativeIsGPUAvailable(): Boolean
        
        // Phase 3: Advanced mask processing functions
        @JvmStatic
        private external fun nativeRefineMask(maskBytes: ByteArray, width: Int, height: Int, 
                                             operation: String, kernelSize: Int): ByteArray
        @JvmStatic
        private external fun nativeSmoothMaskEdges(maskBytes: ByteArray, width: Int, height: Int, 
                                                  blurSigma: Double): ByteArray
        @JvmStatic
        private external fun nativeOptimizeMask(maskBytes: ByteArray, width: Int, height: Int, 
                                               minArea: Int): ByteArray
        @JvmStatic
        private external fun nativeCreateFeatheredMask(maskBytes: ByteArray, width: Int, height: Int, 
                                                      featherRadius: Int): ByteArray
        
        // Cleanup
        @JvmStatic
        private external fun nativeCleanup()
    }
}