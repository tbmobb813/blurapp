import 'dart:typed_data';

import 'package:blurapp/services/auto_detect_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('AutoDetectService fallback', () {
    test('generateFallbackSegmentationMask returns valid PNG bytes', () async {
      // Create a tiny synthetic image (solid color) as bytes
      final image = img.Image(width: 16, height: 16);
      img.fill(image, color: img.ColorRgb8(128, 128, 128));
      final bytes = Uint8List.fromList(img.encodePng(image));

      final service = await AutoDetectService.create(
          modelPath: 'assets/models/nonexistent.tflite');

      final mask = await service.detectSegmentation(bytes);

      // Fallback should return non-null PNG bytes
      expect(mask, isNotNull);
      expect(mask!.length, greaterThan(0));
    });
  });
}
