import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/auto_detect_service.dart';

void main() {
  group('AutoDetectService', () {
    test('can create face detection service', () async {
      expect(
        () async => await AutoDetectService.create(
            modelPath: 'assets/models/face_detection_short_range.tflite'),
        returnsNormally,
      );
    });

    test('can create segmentation service', () async {
      expect(
        () async => await AutoDetectService.create(
            modelPath: 'assets/models/selfie_segmentation.tflite'),
        returnsNormally,
      );
    });

    test('throws error for unknown model', () async {
      expect(
        () async =>
            await AutoDetectService.create(modelPath: 'unknown_model.tflite'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('detect returns empty list for invalid input', () async {
      final service = await AutoDetectService.create(
          modelPath: 'assets/models/face_detection_short_range.tflite');

      final result = await service.detect(Uint8List(0));
      expect(result, isEmpty);

      service.close();
    });
  });
}
