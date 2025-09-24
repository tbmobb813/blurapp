import 'dart:typed_data';

import 'package:blurapp/services/auto_detect_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../test_framework.dart';

void main() {
  BlurAppTestFramework.testGroup('AutoDetectService Manual Fallback Tests', () {
    // Helper function to create test image
    Uint8List createTestImage({int width = 200, int height = 300}) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(100, 150, 200)); // Blue background
      return Uint8List.fromList(img.encodePng(image));
    }

    BlurAppTestFramework.asyncTest('can create face detection service', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/face_detection_short_range.tflite');

      expect(service, isNotNull);
      expect(service.detectionType, DetectionType.faces);
      expect(service.isAutomaticDetectionAvailable, isFalse); // Manual fallback
      service.close();
    }, level: TestLevel.core);

    BlurAppTestFramework.asyncTest('can create segmentation service', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/selfie_segmentation.tflite');

      expect(service, isNotNull);
      expect(service.detectionType, DetectionType.backgroundSegmentation);
      expect(service.isAutomaticDetectionAvailable, isFalse); // Manual fallback
      service.close();
    }, level: TestLevel.core);

    BlurAppTestFramework.asyncTest('throws error for unknown model', () async {
      expect(
        () async => await AutoDetectService.create(modelPath: 'unknown_model.tflite'),
        throwsA(isA<ArgumentError>()),
      );
    }, level: TestLevel.core);

    BlurAppTestFramework.asyncTest('face detection returns suggested regions', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/face_detection_short_range.tflite');

      final testImageBytes = createTestImage();
      final result = await service.detect(testImageBytes);

      expect(result, isNotEmpty);
      expect(result.first, isA<Rect>());

      // Should suggest region in upper portion for portraits
      final suggestion = result.first;
      expect(suggestion.top, lessThan(suggestion.bottom));
      expect(suggestion.left, lessThan(suggestion.right));

      service.close();
    }, level: TestLevel.misc);

    BlurAppTestFramework.asyncTest('segmentation returns full image region', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/selfie_segmentation.tflite');

      final testImageBytes = createTestImage();
      final result = await service.detect(testImageBytes);

      expect(result, hasLength(1));

      // Should return full image rect for manual masking
      final region = result.first;
      expect(region.left, equals(0.0));
      expect(region.top, equals(0.0));
      expect(region.width, equals(200.0));
      expect(region.height, equals(300.0));

      service.close();
    }, level: TestLevel.core);

    BlurAppTestFramework.asyncTest('segmentation mask generation works', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/selfie_segmentation.tflite');

      final testImageBytes = createTestImage();
      final maskBytes = await service.detectSegmentation(testImageBytes);

      expect(maskBytes, isNotNull);
      expect(maskBytes!.isNotEmpty, isTrue);

      // Should be a valid PNG image
      final maskImage = img.decodePng(maskBytes);
      expect(maskImage, isNotNull);
      expect(maskImage!.width, equals(200));
      expect(maskImage.height, equals(300));

      service.close();
    }, level: TestLevel.misc);

    BlurAppTestFramework.asyncTest('face detection service returns null for segmentation', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/face_detection_short_range.tflite');

      final testImageBytes = createTestImage();
      final maskBytes = await service.detectSegmentation(testImageBytes);

      expect(maskBytes, isNull); // Face detection doesn't provide segmentation

      service.close();
    }, level: TestLevel.misc);

    BlurAppTestFramework.asyncTest('handles invalid image data gracefully', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/face_detection_short_range.tflite');

      final result = await service.detect(Uint8List(0));
      expect(result, isEmpty);

      service.close();
    }, level: TestLevel.misc);

    BlurAppTestFramework.asyncTest('landscape images get multiple face suggestions', () async {
      final service = await AutoDetectService.create(modelPath: 'assets/models/face_detection_short_range.tflite');

      // Create wide landscape image
      final landscapeImageBytes = createTestImage(width: 400, height: 200);
      final result = await service.detect(landscapeImageBytes);

      expect(result.length, greaterThan(1)); // Should suggest multiple regions

      // Verify suggestions are in reasonable positions
      for (final suggestion in result) {
        expect(suggestion.width, greaterThan(0));
        expect(suggestion.height, greaterThan(0));
        expect(suggestion.left, greaterThanOrEqualTo(0));
        expect(suggestion.top, greaterThanOrEqualTo(0));
      }

      service.close();
    }, level: TestLevel.misc);
  });
}
