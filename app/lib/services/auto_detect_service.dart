import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum DetectionType { faces, backgroundSegmentation }

/// Manual-only AutoDetectService to avoid loading native plugins during tests.
///
/// Keeps the same public API as the ML-backed version but only uses
/// lightweight heuristics so unit tests and analysis don't import native
/// plugin code.
class AutoDetectService {
  final DetectionType _type;

  AutoDetectService._(this._type);

  /// Create service. modelPath is accepted for API compatibility but ignored
  /// in this fallback-only implementation.
  static Future<AutoDetectService> create({required String modelPath}) async {
    // If we can infer the model intent from the filename, use it.
    // If the caller passed a path (contains '/'), accept it and default to
    // background segmentation. If they passed a bare unknown filename, treat
    // it as an error to catch accidental misuse in tests.
    late final DetectionType type;
    if (modelPath.contains('face_detection')) {
      type = DetectionType.faces;
    } else if (modelPath.contains('selfie_segmentation')) {
      type = DetectionType.backgroundSegmentation;
    } else if (modelPath.contains('/')) {
      // Accept paths (e.g. assets/models/nonexistent.tflite) and default to segmentation
      type = DetectionType.backgroundSegmentation;
    } else {
      throw ArgumentError('Unknown model type for path: $modelPath');
    }

    return AutoDetectService._(type);
  }

  /// Returns suggested bounding boxes for faces or regions.
  Future<List<Rect>> detect(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) return [];
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return [];

      switch (_type) {
        case DetectionType.faces:
          return _suggestFaceRegions(image);
        case DetectionType.backgroundSegmentation:
          return _suggestBackgroundRegions(image);
      }
    } catch (e, st) {
      debugPrint('AutoDetectService.detect error: $e\n$st');
    }
    return [];
  }

  /// Returns a PNG-encoded grayscale mask where white (255) indicates
  /// background (to be blurred) and black (0) indicates foreground.
  Future<Uint8List?> detectSegmentation(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) return null;
    try {
      // Face-detection mode does not provide segmentation masks.
      if (_type == DetectionType.faces) return null;
      return await _generateFallbackSegmentationMask(imageBytes);
    } catch (e, st) {
      debugPrint('AutoDetectService.detectSegmentation error: $e\n$st');
      return null;
    }
  }

  List<Rect> _suggestFaceRegions(img.Image image) {
    final suggestions = <Rect>[];
    final centerX = image.width / 2.0;
    final upperThirdY = image.height / 3.0;

    final faceSize = (image.width * 0.3).clamp(100.0, 400.0);

    suggestions.add(Rect.fromCenter(
      center: Offset(centerX, upperThirdY),
      width: faceSize,
      height: faceSize,
    ));

    if (image.width > image.height * 1.5) {
      suggestions.add(Rect.fromCenter(
        center: Offset(image.width * 0.25, upperThirdY),
        width: faceSize * 0.8,
        height: faceSize * 0.8,
      ));
      suggestions.add(Rect.fromCenter(
        center: Offset(image.width * 0.75, upperThirdY),
        width: faceSize * 0.8,
        height: faceSize * 0.8,
      ));
    }

    return suggestions;
  }

  List<Rect> _suggestBackgroundRegions(img.Image image) {
    return [
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble())
    ];
  }

  Future<Uint8List?> _generateFallbackSegmentationMask(
      Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final mask = img.Image(width: image.width, height: image.height);

    final centerX = image.width / 2.0;
    final centerY = image.height / 2.0;
    final radiusX = image.width * 0.35;
    final radiusY = image.height * 0.6;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final dx = (x - centerX) / radiusX;
        final dy = (y - centerY) / radiusY;
        final distance = dx * dx + dy * dy;
        final isBackground = distance > 1.0;
        final alpha = isBackground ? 255 : 0;
        mask.setPixelRgba(x, y, 255, 255, 255, alpha);
      }
    }

    return Uint8List.fromList(img.encodePng(mask));
  }

  void close() => debugPrint('AutoDetectService: Closed (manual-only)');

  bool get isAutomaticDetectionAvailable => false;
  DetectionType get detectionType => _type;
}
