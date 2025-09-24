import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Blur types for MVP
enum BlurType {
  gaussian,
  pixelate,
  mosaic,
}

/// MVP Blur Engine for Sprint 1
///
/// Focused on core image blurring functionality:
/// - Gaussian blur for faces/backgrounds
/// - Simple pixelate/mosaic effects
/// - Brush-based masking
/// - Real-time preview performance
class BlurEngineMVP {
  static const String _tag = 'BlurEngineMVP';

  /// Apply blur to an image with mask
  ///
  /// [imageBytes] - Original image as JPEG/PNG bytes
  /// [mask] - Grayscale mask (255 = fully blur, 0 = no blur)
  /// [blurType] - Type of blur effect
  /// [strength] - Blur strength (0.0 to 1.0)
  /// [workingWidth] - Working resolution width for performance
  /// [workingHeight] - Working resolution height for performance
  static Future<Uint8List?> applyBlur({
    required Uint8List imageBytes,
    required Uint8List mask,
    required BlurType blurType,
    required double strength,
    int? workingWidth,
    int? workingHeight,
  }) async {
    try {
      // Decode image
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      // Get dimensions
      final int imageWidth = originalImage.width;
      final int imageHeight = originalImage.height;

      // Use working resolution for performance
      final int targetWidth = workingWidth ?? imageWidth;
      final int targetHeight = workingHeight ?? imageHeight;

      debugPrint(
          '$_tag: Processing ${imageWidth}x$imageHeight image at ${targetWidth}x$targetHeight working resolution');

      // Create blur effect based on type
      ui.Image blurredImage;
      switch (blurType) {
        case BlurType.gaussian:
          blurredImage = await _applyGaussianBlur(originalImage, strength);
          break;
        case BlurType.pixelate:
          blurredImage = await _applyPixelate(originalImage, strength);
          break;
        case BlurType.mosaic:
          blurredImage = await _applyMosaic(originalImage, strength);
          break;
      }

      // Composite with mask
      final ui.Image result = await _compositeWithMask(
        originalImage,
        blurredImage,
        mask,
        targetWidth,
        targetHeight,
      );

      // Convert back to bytes
      final ByteData? byteData =
          await result.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('$_tag: Failed to encode result image');
        return null;
      }

      // Cleanup
      originalImage.dispose();
      blurredImage.dispose();
      result.dispose();

      debugPrint('$_tag: Blur processing completed');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('$_tag: Error applying blur: $e');
      return null;
    }
  }

  /// Create a simple brush mask
  ///
  /// [width] - Mask width
  /// [height] - Mask height
  /// [brushStrokes] - List of brush strokes with positions and sizes
  static Future<Uint8List> createBrushMask({
    required int width,
    required int height,
    required List<BrushStroke> brushStrokes,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Fill with transparent
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0x00000000),
    );

    // Draw brush strokes
    for (final stroke in brushStrokes) {
      final Paint paint = Paint()
        ..color =
            Color.fromARGB(255, stroke.opacity, stroke.opacity, stroke.opacity)
        ..style = PaintingStyle.fill;

      for (final point in stroke.points) {
        canvas.drawCircle(
          Offset(point.x, point.y),
          stroke.size,
          paint,
        );
      }
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    // Convert RGBA to grayscale mask
    if (byteData != null) {
      final Uint8List rgba = byteData.buffer.asUint8List();
      final Uint8List mask = Uint8List(width * height);

      for (int i = 0; i < width * height; i++) {
        // Use red channel as mask value
        mask[i] = rgba[i * 4];
      }

      return mask;
    }

    // Fallback: empty mask
    return Uint8List(width * height);
  }

  /// Generate face detection mask (placeholder for MediaPipe integration)
  ///
  /// This is a placeholder that will be replaced with actual MediaPipe/TFLite
  /// face detection in Sprint 1
  static Future<Uint8List?> generateFaceMask({
    required Uint8List imageBytes,
    required int width,
    required int height,
  }) async {
    // NOTE: Face detection is implemented outside this engine in
    // `AutoDetectService` (TFLite or manual fallback). This method
    // remains a local placeholder for callers that do not use
    // AutoDetectService and returns a simple center mask.
    debugPrint(
        '$_tag: Using local placeholder face mask (AutoDetectService recommended)');

    // Create a simple center mask as placeholder
    final Uint8List mask = Uint8List(width * height);
    final int centerX = width ~/ 2;
    final int centerY = height ~/ 2;
    final int radius = (width * 0.2).round();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int dx = x - centerX;
        final int dy = y - centerY;
        final double distance = math.sqrt((dx * dx + dy * dy).toDouble());

        if (distance < radius) {
          mask[y * width + x] = 255;
        }
      }
    }

    return mask;
  }

  /// Convert a grayscale mask (0-255 per pixel) into a list of brush strokes.
  ///
  /// This is a simple heuristic used by the MVP to convert detected mask
  /// regions into a set of discrete brush strokes that the editor UI can
  /// display and edit. It samples the mask at a given `stride` and emits a
  /// stroke for any sampled pixel above `threshold`. The `baseSize` controls
  /// the visual size of the generated strokes.
  static List<BrushStroke> maskToBrushStrokes(
    Uint8List mask,
    int width,
    int height, {
    int stride = 8,
    int threshold = 128,
    double baseSize = 30.0,
  }) {
    final List<BrushStroke> strokes = [];

    if (mask.length < width * height) return strokes;

    for (int y = 0; y < height; y += stride) {
      for (int x = 0; x < width; x += stride) {
        final int idx = y * width + x;
        final int v = mask[idx];
        if (v > threshold) {
          strokes.add(BrushStroke(
            points: [Point(x.toDouble(), y.toDouble())],
            size: baseSize,
            opacity: v,
          ));
        }
      }
    }

    return strokes;
  }

  // Private helper methods

  static Future<ui.Image> _applyGaussianBlur(
      ui.Image image, double strength) async {
    // Use ImageFilter for GPU acceleration
    final double sigma = strength * 10.0; // Scale strength to reasonable sigma
    final ui.ImageFilter filter =
        ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.saveLayer(null, Paint()..imageFilter = filter);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(image.width, image.height);
  }

  static Future<ui.Image> _applyPixelate(
      ui.Image image, double strength) async {
    // Pixelate by scaling down and up
    final double scale = 1.0 - (strength * 0.95); // Keep some detail
    final int smallWidth = (image.width * scale).round().clamp(1, image.width);
    final int smallHeight =
        (image.height * scale).round().clamp(1, image.height);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Scale down
    canvas.scale(smallWidth / image.width, smallHeight / image.height);
    canvas.drawImage(
        image, Offset.zero, Paint()..filterQuality = FilterQuality.none);

    final ui.Picture smallPicture = recorder.endRecording();
    final ui.Image smallImage =
        await smallPicture.toImage(smallWidth, smallHeight);

    // Scale back up
    final ui.PictureRecorder recorder2 = ui.PictureRecorder();
    final Canvas canvas2 = Canvas(recorder2);

    canvas2.scale(image.width / smallWidth, image.height / smallHeight);
    canvas2.drawImage(
        smallImage, Offset.zero, Paint()..filterQuality = FilterQuality.none);

    final ui.Picture largePicture = recorder2.endRecording();
    return await largePicture.toImage(image.width, image.height);
  }

  static Future<ui.Image> _applyMosaic(ui.Image image, double strength) async {
    // Mosaic is similar to pixelate but with color quantization
    // For MVP, use pixelate as base
    return await _applyPixelate(image, strength);
  }

  static Future<ui.Image> _compositeWithMask(
    ui.Image original,
    ui.Image blurred,
    Uint8List mask,
    int width,
    int height,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw original image
    canvas.drawImage(original, Offset.zero, Paint());

    // Create a simple mask-based compositing for MVP
    // Use simpler approach that works with current Flutter API

    // For MVP, use a patch-based approach to apply blur where mask is active
    final Paint blurPaint = Paint()..blendMode = BlendMode.srcOver;

    // Sample mask and apply blur in regions where mask value > threshold
    for (int y = 0; y < height; y += 8) {
      // Sample every 8 pixels for performance
      for (int x = 0; x < width; x += 8) {
        final int maskIndex = y * width + x;
        if (maskIndex < mask.length && mask[maskIndex] > 128) {
          // Draw blurred patch
          final Rect sourceRect = Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            8.0,
            8.0,
          );
          final Rect destRect = sourceRect;

          canvas.drawImageRect(
            blurred,
            sourceRect,
            destRect,
            blurPaint,
          );
        }
      }
    }

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }
}

/// Brush stroke data for mask creation
class BrushStroke {
  final List<Point> points;
  final double size;
  final int opacity; // 0-255

  const BrushStroke({
    required this.points,
    required this.size,
    required this.opacity,
  });
}

/// Point in brush stroke
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}
