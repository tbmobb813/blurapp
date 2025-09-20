import 'package:blurapp/native/hybrid_blur_bindings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: OpenCV Blur Engine Tests', () {
    const MethodChannel channel = MethodChannel('blur_core');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getVersion':
            return 'BlurCore v2.0.0 (MediaPipe disabled) (OpenCV enabled + GPU)';

          case 'isOpenCVAvailable':
            return true;

          case 'isGPUAvailable':
            return true;

          case 'applyAdvancedBlur':
            final args = methodCall.arguments as Map;
            final imageBytes = args['imageBytes'] as Uint8List;
            final sigma = args['sigma'] as double;
            final blurType = args['blurType'] as int;

            // Simulate successful OpenCV blur processing
            if (sigma > 0 && imageBytes.isNotEmpty && blurType >= 0) {
              // Return modified image data (simulate blur effect)
              final factor =
                  blurType == 1 ? 0.7 : 0.8; // Different effect for box blur
              final result = Uint8List.fromList(imageBytes
                  .map((b) => (b * factor).round().clamp(0, 255))
                  .toList());
              return result;
            }
            return Uint8List(0);

          case 'applySelectiveBlur':
            final args = methodCall.arguments as Map;
            final imageBytes = args['imageBytes'] as Uint8List;
            final maskBytes = args['maskBytes'] as Uint8List;
            final fgSigma = args['foregroundSigma'] as double;
            final bgSigma = args['backgroundSigma'] as double;

            // Simulate selective blur processing
            if (imageBytes.isNotEmpty && maskBytes.isNotEmpty) {
              final blurFactor = bgSigma > fgSigma ? 0.9 : 0.95;
              final result = Uint8List.fromList(imageBytes
                  .map((b) => (b * blurFactor).round().clamp(0, 255))
                  .toList());
              return result;
            }
            return Uint8List(0);

          case 'getProcessingCapabilities':
            return {
              'nativeAvailable': true,
              'segmentationAvailable': false,
              'openCVAvailable': true,
              'gpuAvailable': true,
              'version': 'BlurCore v2.0.0 (OpenCV enabled + GPU)',
              'supportedBlurTypes': ['gaussian', 'box', 'motion'],
              'maxImageSize': 4096,
              'selectiveBlur': true,
              'advancedBlur': true,
            };

          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should detect OpenCV availability', () async {
      final available = await NativeBlurBindings.isOpenCVAvailable();

      expect(available, isTrue);
    });

    test('should detect GPU availability', () async {
      final available = await NativeBlurBindings.isGPUAvailable();

      expect(available, isTrue);
    });

    test('should apply advanced Gaussian blur', () async {
      final testImage = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      final result = await NativeBlurBindings.applyAdvancedBlur(
        testImage,
        sigma: 2.5,
        blurType: 0, // Gaussian
      );

      expect(result, isNotNull);
      expect(result!.length, equals(testImage.length));
      expect(result, isNot(equals(testImage))); // Should be modified
    });

    test('should apply advanced Box blur', () async {
      final testImage = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      final result = await NativeBlurBindings.applyAdvancedBlur(
        testImage,
        sigma: 3.0,
        blurType: 1, // Box blur
      );

      expect(result, isNotNull);
      expect(result!.length, equals(testImage.length));
    });

    test('should apply advanced Motion blur', () async {
      final testImage = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      final result = await NativeBlurBindings.applyAdvancedBlur(
        testImage,
        sigma: 2.0,
        blurType: 2, // Motion blur
      );

      expect(result, isNotNull);
      expect(result!.length, equals(testImage.length));
    });

    test('should apply selective blur with mask', () async {
      final testImage = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final testMask =
          Uint8List.fromList(List.generate(250, (i) => i % 2 == 0 ? 255 : 0));

      final result = await NativeBlurBindings.applySelectiveBlur(
        testImage,
        testMask,
        foregroundSigma: 0.5,
        backgroundSigma: 8.0,
      );

      expect(result, isNotNull);
      expect(result!.length, equals(testImage.length));
      expect(result, isNot(equals(testImage))); // Should be modified
    });

    test('should handle zero sigma gracefully', () async {
      final testImage = Uint8List.fromList(List.generate(100, (i) => i % 256));

      final result = await NativeBlurBindings.applyAdvancedBlur(
        testImage,
        sigma: 0.0,
        blurType: 0,
      );

      expect(result, isNotNull);
    });

    test('should get enhanced processing capabilities', () async {
      final capabilities = await NativeBlurBindings.getProcessingCapabilities();

      expect(capabilities, isNotNull);
      expect(capabilities!['openCVAvailable'], isTrue);
      expect(capabilities['gpuAvailable'], isTrue);
      expect(capabilities['advancedBlur'], isTrue);
      expect(capabilities['selectiveBlur'], isTrue);
      expect(capabilities['supportedBlurTypes'], contains('gaussian'));
      expect(capabilities['supportedBlurTypes'], contains('box'));
      expect(capabilities['supportedBlurTypes'], contains('motion'));
      expect(capabilities['maxImageSize'], equals(4096));
    });

    test('should validate version includes OpenCV info', () async {
      final version = await NativeBlurBindings.getVersion();

      expect(version, contains('OpenCV'));
      expect(version, contains('v2.0.0'));
    });

    test('should handle large images efficiently', () async {
      // Simulate a larger image (e.g., 1024x1024 RGBA)
      final largeImage =
          Uint8List.fromList(List.generate(1024 * 1024 * 4, (i) => i % 256));

      final result = await NativeBlurBindings.applyAdvancedBlur(
        largeImage,
        sigma: 1.5,
        blurType: 0,
      );

      expect(result, isNotNull);
      expect(result!.length, equals(largeImage.length));
    });

    test('should use legacy compatibility method', () async {
      final testImage = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final testMask = Uint8List.fromList(List.generate(250, (i) => 128));

      final result = await NativeBlurBindings.applySelectiveBlurLegacy(
        testImage,
        testMask,
        5.0, // Legacy blur strength
      );

      expect(result, isNotNull);
      expect(result!.length, equals(testImage.length));
    });
  });
}
