import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum BlurType { gaussian, pixelate, mosaic }

/// Performance-optimized blur pipeline with memory management
class BlurPipeline {
  // Memory and performance constants
  static const int _maxImageDimension = 2048; // Max width/height for processing
  static const int _maxImagePixels = 4 * 1024 * 1024; // 4MP max for performance
  static const int _previewMaxDimension =
      512; // For preview/real-time processing

  /// Apply blur with automatic memory management and performance optimization
  static Uint8List applyBlur(
    Uint8List imageBytes,
    BlurType type,
    int strength, {
    bool isPreview = false,
  }) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Memory safety: Check image size and downsample if needed
      final processImage = _prepareImageForProcessing(
        image,
        isPreview: isPreview,
      );

      img.Image processedImage;

      // Clamp strength values for safety and performance
      final clampedStrength = _clampStrengthValue(strength, type);

      switch (type) {
        case BlurType.gaussian:
          processedImage = _gaussianBlur(processImage, clampedStrength);
          break;
        case BlurType.pixelate:
          processedImage = _pixelate(processImage, clampedStrength);
          break;
        case BlurType.mosaic:
          processedImage = _mosaic(processImage, clampedStrength);
          break;
      }

      // Encode with appropriate quality for memory efficiency
      final quality = isPreview ? 75 : 90;
      return Uint8List.fromList(
        img.encodeJpg(processedImage, quality: quality),
      );
    } catch (e) {
      debugPrint('BlurPipeline error: $e');
      // If blur fails, return original image
      return imageBytes;
    }
  }

  /// Prepare image for processing with memory constraints
  static img.Image _prepareImageForProcessing(
    img.Image image, {
    bool isPreview = false,
  }) {
    final maxDimension = isPreview ? _previewMaxDimension : _maxImageDimension;
    final maxPixels = isPreview
        ? _previewMaxDimension * _previewMaxDimension
        : _maxImagePixels;

    // Check if image is too large
    final totalPixels = image.width * image.height;
    final needsResize =
        image.width > maxDimension ||
        image.height > maxDimension ||
        totalPixels > maxPixels;

    if (!needsResize) {
      return image;
    }

    // Calculate new dimensions while maintaining aspect ratio
    double scale = 1.0;

    if (image.width > maxDimension || image.height > maxDimension) {
      scale =
          maxDimension /
          (image.width > image.height ? image.width : image.height);
    }

    if (totalPixels > maxPixels) {
      final pixelScale = sqrt(maxPixels / totalPixels);
      scale = scale < pixelScale ? scale : pixelScale;
    }

    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    debugPrint(
      'BlurPipeline: Resizing ${image.width}x${image.height} to ${newWidth}x$newHeight for processing',
    );

    return img.copyResize(image, width: newWidth, height: newHeight);
  }

  /// Clamp strength values for safety and optimal performance
  static int _clampStrengthValue(int strength, BlurType type) {
    switch (type) {
      case BlurType.gaussian:
        return strength.clamp(1, 50); // Gaussian blur radius limit
      case BlurType.pixelate:
      case BlurType.mosaic:
        return strength.clamp(1, 32); // Block size limit
    }
  }

  /// Helper function for square root (imported from dart:math would add dependency)
  static double sqrt(num value) {
    if (value < 0) return double.nan;
    if (value == 0) return 0.0;

    // Newton's method for square root
    double x = value.toDouble();
    double prev;
    do {
      prev = x;
      x = (x + value / x) / 2;
    } while ((x - prev).abs() > 0.001);

    return x;
  }

  static img.Image _gaussianBlur(img.Image image, int strength) {
    // Apply Gaussian blur using the image package
    return img.gaussianBlur(image, radius: strength);
  }

  static img.Image _pixelate(img.Image image, int strength) {
    // Create pixelate effect by scaling down and back up
    final blockSize = strength.clamp(1, 32).toInt();
    final smallWidth = (image.width / blockSize).round();
    final smallHeight = (image.height / blockSize).round();

    final small = img.copyResize(
      image,
      width: smallWidth,
      height: smallHeight,
      interpolation: img.Interpolation.nearest,
    );
    return img.copyResize(
      small,
      width: image.width,
      height: image.height,
      interpolation: img.Interpolation.nearest,
    );
  }

  static img.Image _mosaic(img.Image image, int strength) {
    // Similar to pixelate but with a different algorithm
    final blockSize = strength.clamp(1, 32);
    final result = img.Image.from(image);

    for (int y = 0; y < image.height; y += blockSize) {
      for (int x = 0; x < image.width; x += blockSize) {
        // Get average color of the block
        int r = 0, g = 0, b = 0, count = 0;

        for (int dy = 0; dy < blockSize && y + dy < image.height; dy++) {
          for (int dx = 0; dx < blockSize && x + dx < image.width; dx++) {
            final px = image.getPixel(x + dx, y + dy);
            // image.getPixel returns a 32-bit int in ARGB format. Extract channels.
            // Pixel is an object with channel getters; convert to int
            final int red = px.r.toInt();
            final int green = px.g.toInt();
            final int blue = px.b.toInt();
            r += red;
            g += green;
            b += blue;
            count++;
          }
        }

        if (count > 0) {
          final avgR = r ~/ count;
          final avgG = g ~/ count;
          final avgB = b ~/ count;
          // Compose ARGB (opaque) pixel
          // Use image package Color type
          final avgColor = img.ColorRgb8(avgR, avgG, avgB);

          // Fill the block with average color
          for (int dy = 0; dy < blockSize && y + dy < image.height; dy++) {
            for (int dx = 0; dx < blockSize && x + dx < image.width; dx++) {
              result.setPixel(x + dx, y + dy, avgColor);
            }
          }
        }
      }
    }

    return result;
  }
}
