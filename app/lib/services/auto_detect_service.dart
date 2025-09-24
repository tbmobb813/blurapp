import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
// TFLite runtime and helpers. These are optional at runtime; create() will
// fall back to manual heuristics if interpreter loading fails.
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

enum DetectionType { faces, backgroundSegmentation }

/// Privacy-first auto-detection service with graceful fallbacks
///
/// For MVP, this service provides manual selection tools instead of
/// heavy ML dependencies. Future versions can add TensorFlow Lite
/// when better platform support is available.
class AutoDetectService {
  final DetectionType _type;
  bool _useManualFallback;
  tfl.Interpreter? _interpreter;

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

    // Try to load interpreter from asset. The caller may pass either
    // 'assets/models/<name>.tflite' or just the filename. Normalize to the
    // filename for Interpreter.fromAsset.
    String modelAsset = modelPath.split('/').last;

    final service = AutoDetectService._(type, true);

    try {
      debugPrint('AutoDetectService: Loading model asset: $modelAsset');
      service._interpreter = await tfl.Interpreter.fromAsset(modelAsset);
      service._useManualFallback = false;
      debugPrint('AutoDetectService: Model loaded successfully');
    } catch (e) {
      debugPrint('AutoDetectService: Failed to load model, falling back: $e');
      service._interpreter = null;
      service._useManualFallback = true;
    }

    return service;
  }

  /// Detect faces or generate segmentation suggestions
  ///
  /// For manual fallback mode, returns suggested regions for user to refine:
  /// - Face detection: Returns center region of image as starting point
  /// - Background segmentation: Returns full image rect for manual masking
  Future<List<Rect>> detect(Uint8List imageBytes) async {
    try {
      if (_useManualFallback || _interpreter == null) {
        return await _manualFallbackDetection(imageBytes);
      }

      if (_type == DetectionType.faces) {
        final boxes = await _runFaceDetectionModel(imageBytes);
        if (boxes != null && boxes.isNotEmpty) return boxes;
        return await _manualFallbackDetection(imageBytes);
      }

      return await _manualFallbackDetection(imageBytes);
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
      if (_useManualFallback || _interpreter == null) {
        return await _generateFallbackSegmentationMask(imageBytes);
      }

      final mask = await _runSegmentationModel(imageBytes);
      if (mask != null) return mask;
      return await _generateFallbackSegmentationMask(imageBytes);
    } catch (e) {
      debugPrint('Segmentation error: $e');
      return await _generateFallbackSegmentationMask(imageBytes);
    }
  }

  /// Run a selfie-segmentation model and return a PNG-encoded grayscale mask
  /// with dimensions equal to the original image.
  Future<Uint8List?> _runSegmentationModel(Uint8List imageBytes) async {
    if (_interpreter == null) return null;

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      // Prepare input tensor by resizing the image to model input dimensions
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape; // [1, H, W, C]
      final targetH = inputShape.length > 1 ? inputShape[1] : decoded.height;
      final targetW = inputShape.length > 2 ? inputShape[2] : decoded.width;
      final channels = inputShape.length > 3 ? inputShape[3] : 3;

      final resized = img.copyResize(decoded,
          width: targetW,
          height: targetH,
          interpolation: img.Interpolation.linear);

      // Create input buffer depending on tensor type
      final tfl.TfLiteType inType = inputTensor.type;
      dynamic inputBuffer;
      if (inType == tfl.TfLiteType.float32) {
        final buffer = Float32List(targetH * targetW * channels);
        int idx = 0;
        for (int y = 0; y < targetH; y++) {
          for (int x = 0; x < targetW; x++) {
            final p = resized.getPixel(x, y);
            final r = p.r / 255.0;
            final g = p.g / 255.0;
            final b = p.b / 255.0;
            buffer[idx++] = r;
            if (channels > 1) buffer[idx++] = g;
            if (channels > 2) buffer[idx++] = b;
          }
        }
        inputBuffer = buffer;
      } else {
        // treat as uint8 input
        final buffer = Uint8List(targetH * targetW * channels);
        int idx = 0;
        for (int y = 0; y < targetH; y++) {
          for (int x = 0; x < targetW; x++) {
            final p = resized.getPixel(x, y);
            buffer[idx++] = p.r.toInt();
            if (channels > 1) buffer[idx++] = p.g.toInt();
            if (channels > 2) buffer[idx++] = p.b.toInt();
          }
        }
        inputBuffer = buffer;
      }

      // Prepare output buffer
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape; // e.g. [1, H, W, 1]
      final outH = outputShape.length > 1 ? outputShape[1] : targetH;
      final outW = outputShape.length > 2 ? outputShape[2] : targetW;

      final outSize =
          outH * outW * (outputShape.length > 3 ? outputShape[3] : 1);
      Float32List outBuffer = Float32List(outSize);

      // Run inference
      _interpreter!.run(inputBuffer, outBuffer);

      // Build grayscale image from output buffer
      final maskImg = img.Image(width: outW, height: outH);
      for (int y = 0; y < outH; y++) {
        for (int x = 0; x < outW; x++) {
          final v = outBuffer[y * outW + x];
          final byteVal = (v.clamp(0.0, 1.0) * 255).round();
          maskImg.setPixelRgba(x, y, byteVal, byteVal, byteVal, 255);
        }
      }

      // Resize mask back to original image size
      final resizedMask = img.copyResize(maskImg,
          width: decoded.width,
          height: decoded.height,
          interpolation: img.Interpolation.linear);

      return Uint8List.fromList(img.encodePng(resizedMask));
    } catch (e) {
      debugPrint('AutoDetectService: Segmentation inference failed: $e');
      return null;
    }
  }

  /// Run a face-detection model (e.g., BlazeFace) and return bounding boxes
  /// in original image pixel coordinates. Returns null on failure.
  Future<List<Rect>?> _runFaceDetectionModel(Uint8List imageBytes) async {
    if (_interpreter == null) return null;

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final originalW = decoded.width;
      final originalH = decoded.height;

      // Prepare input image
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape; // [1, H, W, C]
      final targetH = inputShape.length > 1 ? inputShape[1] : decoded.height;
      final targetW = inputShape.length > 2 ? inputShape[2] : decoded.width;
      final channels = inputShape.length > 3 ? inputShape[3] : 3;

      final resized = img.copyResize(decoded,
          width: targetW,
          height: targetH,
          interpolation: img.Interpolation.linear);

      // Build input buffer
      final inType = inputTensor.type;
      dynamic inputBuffer;
      if (inType == tfl.TfLiteType.float32) {
        final buffer = Float32List(targetH * targetW * channels);
        int idx = 0;
        for (int y = 0; y < targetH; y++) {
          for (int x = 0; x < targetW; x++) {
            final p = resized.getPixel(x, y);
            buffer[idx++] = p.r / 255.0;
            if (channels > 1) buffer[idx++] = p.g / 255.0;
            if (channels > 2) buffer[idx++] = p.b / 255.0;
          }
        }
        inputBuffer = buffer;
      } else {
        final buffer = Uint8List(targetH * targetW * channels);
        int idx = 0;
        for (int y = 0; y < targetH; y++) {
          for (int x = 0; x < targetW; x++) {
            final p = resized.getPixel(x, y);
            buffer[idx++] = p.r.toInt();
            if (channels > 1) buffer[idx++] = p.g.toInt();
            if (channels > 2) buffer[idx++] = p.b.toInt();
          }
        }
        inputBuffer = buffer;
      }

      // Prepare outputs - usually boxes and scores
      final out0 = _interpreter!.getOutputTensor(0);
      final outShape0 = out0.shape; // e.g. [1, N, 4]
      final outSize0 = outShape0.reduce((a, b) => a * b);
      final outBuffer0 = Float32List(outSize0);

      Float32List? scoresBuffer;
      final outputTensors = _interpreter!.getOutputTensors();
      if (outputTensors.length > 1) {
        final out1 = _interpreter!.getOutputTensor(1);
        final outSize1 = out1.shape.reduce((a, b) => a * b);
        scoresBuffer = Float32List(outSize1);
      }

      if (scoresBuffer != null) {
        // run with multiple outputs - some API accept a map for outputs
        _interpreter!.runForMultipleInputs(
            [inputBuffer], {0: outBuffer0, 1: scoresBuffer});
      } else {
        _interpreter!.run(inputBuffer, outBuffer0);
      }

      final boxesList = outBuffer0.toList();
      final scoresList = scoresBuffer?.toList();

      final int numBoxes = (boxesList.length / 4).floor();
      final List<Rect> results = [];
      const double scoreThreshold = 0.5;

      for (int i = 0; i < numBoxes; i++) {
        final double y1 = boxesList[i * 4 + 0];
        final double x1 = boxesList[i * 4 + 1];
        final double y2 = boxesList[i * 4 + 2];
        final double x2 = boxesList[i * 4 + 3];

        double score = 1.0;
        if (scoresList != null && i < scoresList.length) score = scoresList[i];

        if (score < scoreThreshold) continue;

        // Coordinates are typically normalized [0,1]
        final left = (x1 * originalW).clamp(0, originalW).toDouble();
        final top = (y1 * originalH).clamp(0, originalH).toDouble();
        final right = (x2 * originalW).clamp(0, originalW).toDouble();
        final bottom = (y2 * originalH).clamp(0, originalH).toDouble();

        results.add(Rect.fromLTRB(left, top, right, bottom));
      }

      return results;
    } catch (e) {
      debugPrint('AutoDetectService: Face inference failed: $e');
      return null;
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
