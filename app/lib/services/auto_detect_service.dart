import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

enum DetectionType { faces, backgroundSegmentation }

class AutoDetectService {
  final Interpreter? _interpreter;
  final DetectionType _type;

  AutoDetectService._(this._interpreter, this._type);

  static Future<AutoDetectService> create({required String modelPath}) async {
    final interpreter = await Interpreter.fromAsset(modelPath);

    // Determine detection type based on model filename
    final DetectionType type;
    if (modelPath.contains('face_detection')) {
      type = DetectionType.faces;
    } else if (modelPath.contains('selfie_segmentation')) {
      type = DetectionType.backgroundSegmentation;
    } else {
      throw ArgumentError('Unknown model type for path: $modelPath');
    }

    return AutoDetectService._(interpreter, type);
  }

  /// Detect faces or generate segmentation mask.
  /// For face detection: Returns list of Rects for detected face regions
  /// For segmentation: Returns a single Rect covering the entire image (mask available via detectSegmentation)
  Future<List<Rect>> detect(Uint8List imageBytes) async {
    if (_interpreter == null) return [];

    try {
      switch (_type) {
        case DetectionType.faces:
          return await _detectFaces(imageBytes);
        case DetectionType.backgroundSegmentation:
          // For segmentation, return full image rect
          final image = img.decodeImage(imageBytes);
          if (image == null) return [];
          return [
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble())
          ];
      }
    } catch (e) {
      debugPrint('Detection error: $e');
      return [];
    }
  }

  /// Get segmentation mask for background/foreground separation
  /// Returns null for face detection models
  Future<Uint8List?> detectSegmentation(Uint8List imageBytes) async {
    if (_interpreter == null || _type != DetectionType.backgroundSegmentation) {
      return null;
    }

    try {
      return await _generateSegmentationMask(imageBytes);
    } catch (e) {
      debugPrint('Segmentation error: $e');
      return null;
    }
  }

  Future<List<Rect>> _detectFaces(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return [];

    // Resize image to model input size (BlazeFace expects 128x128)
    const inputSize = 128;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Convert to float32 tensor [1, 128, 128, 3] normalized to [-1, 1]
    final input = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        // Normalize RGB to [-1, 1]
        input[pixelIndex++] = (pixel.r / 127.5) - 1.0;
        input[pixelIndex++] = (pixel.g / 127.5) - 1.0;
        input[pixelIndex++] = (pixel.b / 127.5) - 1.0;
      }
    }

    // Prepare output tensors
    // BlazeFace outputs: classification and regression
    final outputClassification = Float32List(896); // 896 anchors
    final outputRegression =
        Float32List(896 * 16); // 896 anchors * 16 coordinates

    // Run inference
    _interpreter!.run(
        input.buffer
            .asUint8List()
            .buffer
            .asFloat32List()
            .reshape([1, inputSize, inputSize, 3]),
        {
          0: outputClassification.reshape([1, 896, 1]),
          1: outputRegression.reshape([1, 896, 16]),
        });

    // Post-process results
    final faces = <Rect>[];
    const confidenceThreshold = 0.5;
    final scaleX = image.width / inputSize;
    final scaleY = image.height / inputSize;

    for (int i = 0; i < 896; i++) {
      final score = 1.0 / (1.0 + math.exp(-outputClassification[i])); // Sigmoid

      if (score > confidenceThreshold) {
        // Extract bounding box (simplified - real implementation needs anchor decoding)
        final baseIndex = i * 16;
        final centerX = outputRegression[baseIndex] * scaleX;
        final centerY = outputRegression[baseIndex + 1] * scaleY;
        final width = outputRegression[baseIndex + 2] * scaleX;
        final height = outputRegression[baseIndex + 3] * scaleY;

        final rect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: width,
          height: height,
        );

        faces.add(rect);
      }
    }

    return faces;
  }

  Future<Uint8List?> _generateSegmentationMask(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // Resize image to model input size (Selfie Segmentation expects 256x256)
    const inputSize = 256;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Convert to float32 tensor [1, 256, 256, 3] normalized to [0, 1]
    final input = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        // Normalize RGB to [0, 1]
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    // Prepare output tensor [1, 256, 256, 1]
    final output = Float32List(inputSize * inputSize);

    // Run inference
    _interpreter!.run(
      input.buffer
          .asUint8List()
          .buffer
          .asFloat32List()
          .reshape([1, inputSize, inputSize, 3]),
      output.reshape([1, inputSize, inputSize, 1]),
    );

    // Convert mask to original image size and create binary mask
    final originalMask = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Sample from resized mask
        final maskX =
            (x * inputSize / image.width).round().clamp(0, inputSize - 1);
        final maskY =
            (y * inputSize / image.height).round().clamp(0, inputSize - 1);
        final maskValue = output[maskY * inputSize + maskX];

        // Apply threshold (> 0.5 = foreground/person, <= 0.5 = background)
        final isBackground = maskValue <= 0.5;
        final alpha = isBackground ? 255 : 0; // 255 = mask this area, 0 = keep

        originalMask.setPixel(x, y, img.ColorRgba8(255, 255, 255, alpha));
      }
    }

    return Uint8List.fromList(img.encodePng(originalMask));
  }

  void close() {
    _interpreter?.close();
  }
}
