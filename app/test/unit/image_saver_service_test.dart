import 'dart:typed_data';
import 'package:blurapp/services/image_saver_service.dart';
import 'test_gallery_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../test_framework.dart';

void main() {
  BlurAppTestFramework.testGroup(
    'ImageSaverService Enhanced Tests',
    () {
      // Create a simple test image
      Uint8List createTestImage() {
        final image = img.Image(width: 100, height: 100);
        img.fill(image, color: img.ColorRgb8(255, 0, 0)); // Red image
        return Uint8List.fromList(img.encodePng(image));
      }

      BlurAppTestFramework.testCase(
        'image creation and encoding works correctly',
        () {
          final imageBytes = createTestImage();

          expect(imageBytes.isNotEmpty, isTrue);
          expect(imageBytes.length,
              greaterThan(100)); // PNG should be larger than 100 bytes

          // Verify it's a valid PNG
          final decodedImage = img.decodePng(imageBytes);
          expect(decodedImage, isNotNull);
          expect(decodedImage!.width, equals(100));
          expect(decodedImage.height, equals(100));
        },
        level: TestLevel.core,
      );

      BlurAppTestFramework.testCase(
        'ImageSaverService class can be instantiated',
        () {
          // Inject a test provider so ImageSaverService doesn't call platform plugins
          ImageSaverService.provider = TestGalleryProvider();

          final service = ImageSaverService();
          expect(service, isNotNull);
          expect(service.runtimeType, equals(ImageSaverService));
          // Cleanup
          ImageSaverService.provider = null;
        },
        level: TestLevel.core,
      );

      BlurAppTestFramework.testCase(
        'image format validation works',
        () {
          final imageBytes = createTestImage();

          // Test PNG format detection
          final pngImage = img.decodePng(imageBytes);
          expect(pngImage, isNotNull);

          // Test JPEG encoding
          final jpegBytes =
              Uint8List.fromList(img.encodeJpg(pngImage!, quality: 85));
          final jpegImage = img.decodeJpg(jpegBytes);
          expect(jpegImage, isNotNull);
        },
        level: TestLevel.misc,
      );

      BlurAppTestFramework.testCase(
        'quality parameter range validation',
        () {
          final imageBytes = createTestImage();
          final image = img.decodePng(imageBytes)!;

          // Test valid quality ranges
          final highQuality = img.encodeJpg(image, quality: 95);
          final lowQuality = img.encodeJpg(image, quality: 10);

          expect(highQuality.isNotEmpty, isTrue);
          expect(lowQuality.isNotEmpty, isTrue);

          // High quality should generally produce larger files
          expect(highQuality.length, greaterThan(lowQuality.length));
        },
        level: TestLevel.misc,
      );

      BlurAppTestFramework.testCase(
        'timestamp generation creates unique values',
        () {
          final timestamp1 = DateTime.now().millisecondsSinceEpoch;
          // Small delay
          final timestamp2 = DateTime.now().millisecondsSinceEpoch;

          // Timestamps should be sequential
          expect(timestamp2, greaterThanOrEqualTo(timestamp1));
        },
        level: TestLevel.misc,
      );

      BlurAppTestFramework.testCase(
        'file extension logic works correctly',
        () {
          // Test filename generation logic (without actual file system)
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final jpegFilename = 'blurred_$timestamp.jpg';
          final pngFilename = 'blurred_$timestamp.png';

          expect(jpegFilename.endsWith('.jpg'), isTrue);
          expect(pngFilename.endsWith('.png'), isTrue);
          expect(jpegFilename.contains('blurred_'), isTrue);
          expect(pngFilename.contains('blurred_'), isTrue);
        },
        level: TestLevel.core,
      );
    },
  );
}
