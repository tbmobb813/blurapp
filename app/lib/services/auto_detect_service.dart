import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum DetectionType { faces, backgroundSegmentation }

/// Privacy-first auto-detection service with graceful fallbacks
///
/// For MVP, this service provides manual selection tools instead of
/// heavy ML dependencies. Future versions can add TensorFlow Lite
/// when better platform support is available.
class AutoDetectService {
  final DetectionType _type;
  final bool _useManualFallback;

  AutoDetectService._(this._type, this._useManualFallback);

  /// Create AutoDetectService with graceful fallback for unsupported platforms
  ///
  /// For MVP, always uses manual fallback to avoid TensorFlow Lite dependency issues
  /// This keeps the app lightweight and ensures privacy-first operation
  static Future<AutoDetectService> create({required String modelPath}) async {
    // Determine detection type based on model filename
    final DetectionType type;
    if (modelPath.contains('face_detection')) {
      type = DetectionType.faces;
    } else if (modelPath.contains('selfie_segmentation')) {
      type = DetectionType.backgroundSegmentation;
    } else {
      throw ArgumentError('Unknown model type for path: $modelPath');
    }

    // For MVP: Always use manual fallback to avoid TensorFlow Lite issues
    // This provides a privacy-first, lightweight solution
    debugPrint('AutoDetectService: Using manual fallback mode for $modelPath');
    return AutoDetectService._(type, true);
  }

  /// Detect faces or generate segmentation suggestions
  ///
  /// For manual fallback mode, returns suggested regions for user to refine:
  /// - Face detection: Returns center region of image as starting point
  /// - Background segmentation: Returns full image rect for manual masking
  Future<List<Rect>> detect(Uint8List imageBytes) async {
    try {
      if (_useManualFallback) {
        return await _manualFallbackDetection(imageBytes);
      }
      // Future: TensorFlow Lite implementation would go here
      return [];
    } catch (e) {
      debugPrint('Detection error: $e');
      return await _manualFallbackDetection(imageBytes);
    }
  }

  /// Get segmentation mask for background/foreground separation
  ///
  /// For manual fallback, returns a default mask that user can refine
  Future<Uint8List?> detectSegmentation(Uint8List imageBytes) async {
    if (_type != DetectionType.backgroundSegmentation) {
      return null;
    }

    try {
      if (_useManualFallback) {
        return await _generateFallbackSegmentationMask(imageBytes);
      }
      // Future: TensorFlow Lite implementation would go here
      return null;
    } catch (e) {
      debugPrint('Segmentation error: $e');
      return await _generateFallbackSegmentationMask(imageBytes);
    }
  }

  /// Manual fallback detection provides starting points for user refinement
  Future<List<Rect>> _manualFallbackDetection(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return []; // Handle empty data gracefully
    }

    final image = img.decodeImage(imageBytes);
    if (image == null) return [];

    switch (_type) {
      case DetectionType.faces:
        return _suggestFaceRegions(image);
      case DetectionType.backgroundSegmentation:
        return _suggestBackgroundRegions(image);
    }
  }

  /// Suggest likely face regions based on common composition rules
  List<Rect> _suggestFaceRegions(img.Image image) {
    final suggestions = <Rect>[];

    // Rule of thirds - faces often appear in upper third
    final centerX = image.width / 2.0;
    final upperThirdY = image.height / 3.0;

    // Suggest a region in the upper center (common portrait composition)
    final faceSize = (image.width * 0.3).clamp(100.0, 400.0);

    suggestions.add(Rect.fromCenter(
      center: Offset(centerX, upperThirdY),
      width: faceSize,
      height: faceSize,
    ));

    // For landscape images, suggest additional regions
    if (image.width > image.height * 1.5) {
      // Left side face region
      suggestions.add(Rect.fromCenter(
        center: Offset(image.width * 0.25, upperThirdY),
        width: faceSize * 0.8,
        height: faceSize * 0.8,
      ));

      // Right side face region
      suggestions.add(Rect.fromCenter(
        center: Offset(image.width * 0.75, upperThirdY),
        width: faceSize * 0.8,
        height: faceSize * 0.8,
      ));
    }

    return suggestions;
  }

  /// Suggest background regions for manual masking
  List<Rect> _suggestBackgroundRegions(img.Image image) {
    // Return full image rect - user will manually mask the foreground
    return [
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble())
    ];
  }

  /// Generate a fallback segmentation mask with default person silhouette
  Future<Uint8List?> _generateFallbackSegmentationMask(
      Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return null; // Handle empty data gracefully
    }

    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // Create a default mask with center region as "foreground" (person)
    // and edges as "background" - user can refine this manually
    final mask = img.Image(width: image.width, height: image.height);

    final centerX = image.width / 2.0;
    final centerY = image.height / 2.0;
    final radiusX = image.width * 0.35; // 35% of width
    final radiusY = image.height * 0.6; // 60% of height (portrait-like)

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Create an elliptical region as "foreground"
        final dx = (x - centerX) / radiusX;
        final dy = (y - centerY) / radiusY;
        final distance = dx * dx + dy * dy;

        // Inside ellipse = foreground (don't mask), outside = background (mask)
        final isBackground = distance > 1.0;
        final alpha = isBackground ? 255 : 0; // 255 = mask this area, 0 = keep

        mask.setPixel(x, y, img.ColorRgba8(255, 255, 255, alpha));
      }
    }

    return Uint8List.fromList(img.encodePng(mask));
  }

  /// No resources to clean up in fallback mode
  void close() {
    // Nothing to close in manual fallback mode
    debugPrint('AutoDetectService: Closed (manual fallback mode)');
  }

  /// Check if automatic detection is available (false for manual fallback)
  bool get isAutomaticDetectionAvailable => !_useManualFallback;

  /// Get the detection type
  DetectionType get detectionType => _type;
}
