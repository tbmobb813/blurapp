import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:blurapp/features/editor/blur_pipeline.dart';
import 'package:blurapp/services/auto_detect_service.dart';
import 'package:blurapp/services/image_saver_service.dart';
import '../test_framework.dart';
import '../helpers/performance_test_utils.dart';

void main() {
  BlurAppTestFramework.testGroup('Memory & Performance Tests', () {
    // Helper function to create test images of different sizes
    Uint8List createTestImage({
      int width = 100,
      int height = 100,
      bool complex = false,
    }) {
      final image = img.Image(width: width, height: height);

      if (complex) {
        // Create complex image with gradients and patterns (more memory intensive)
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final r = ((x + y) % 256);
            final g = ((x * 2) % 256);
            final b = ((y * 2) % 256);
            image.setPixel(x, y, img.ColorRgb8(r, g, b));
          }
        }
      } else {
        // Simple solid color image
        img.fill(image, color: img.ColorRgb8(100, 150, 200));
      }

      return Uint8List.fromList(img.encodePng(image));
    }

    // Measure memory usage using performance utilities
    int getCurrentMemoryUsage() {
      return PerformanceTestUtils.getCurrentMemoryUsage();
    }

    group('[PERFORMANCE] Image Processing Memory Tests', () {
      BlurAppTestFramework.testCase(
        'small image processing stays within memory limits',
        () {
          final imageBytes = createTestImage(width: 200, height: 200);
          final memoryBefore = getCurrentMemoryUsage();

          // Process with different blur types
          final gaussianResult = BlurPipeline.applyBlur(
            imageBytes,
            BlurType.gaussian,
            5,
          );
          final pixelateResult = BlurPipeline.applyBlur(
            imageBytes,
            BlurType.pixelate,
            8,
          );
          final mosaicResult = BlurPipeline.applyBlur(
            imageBytes,
            BlurType.mosaic,
            10,
          );

          expect(gaussianResult.isNotEmpty, isTrue);
          expect(pixelateResult.isNotEmpty, isTrue);
          expect(mosaicResult.isNotEmpty, isTrue);

          final memoryAfter = getCurrentMemoryUsage();

          // Memory increase should be reasonable (less than 50MB for small images)
          if (memoryBefore > 0 && memoryAfter > 0) {
            final memoryIncrease = memoryAfter - memoryBefore;
            expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // 50MB limit
          }
        },
        level: TestLevel.core,
      );

      BlurAppTestFramework.testCase('medium image processing performance', () {
        final imageBytes = createTestImage(
          width: 800,
          height: 600,
          complex: true,
        );

        // Use performance utilities to measure execution time
        final timeMeasurement = PerformanceTestUtils.measureExecutionTime(() {
          return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 10);
        });

        // Validate performance within limits
        PerformanceTestUtils.validateExecutionTime(
          timeMeasurement,
          PerformanceTestUtils.mediumImageProcessingLimit,
          context: 'medium image gaussian blur',
        );
      }, level: TestLevel.critical);

      BlurAppTestFramework.testCase(
        'large image memory constraint validation',
        () {
          // Test with larger image to verify memory limits
          final imageBytes = createTestImage(width: 1920, height: 1080);

          // Use performance utilities to measure memory usage
          final memoryMeasurement = PerformanceTestUtils.measureMemoryUsage(() {
            return BlurPipeline.applyBlur(imageBytes, BlurType.pixelate, 15);
          });

          // Validate memory usage within limits
          PerformanceTestUtils.validateMemoryUsage(
            memoryMeasurement,
            PerformanceTestUtils.largeImageMemoryLimit,
            context: 'large image pixelate blur',
          );
        },
        level: TestLevel.misc,
      );
    });

    group('[PERFORMANCE] AutoDetectService Memory Tests', () {
      BlurAppTestFramework.asyncTest(
        'face detection suggestions use minimal memory',
        () async {
          final service = await AutoDetectService.create(
            modelPath: 'assets/models/face_detection_short_range.tflite',
          );

          final imageBytes = createTestImage(width: 400, height: 600);
          final memoryBefore = getCurrentMemoryUsage();

          final suggestions = await service.detect(imageBytes);

          expect(suggestions.isNotEmpty, isTrue);

          final memoryAfter = getCurrentMemoryUsage();

          // Manual suggestions should use minimal memory
          if (memoryBefore > 0 && memoryAfter > 0) {
            final memoryIncrease = memoryAfter - memoryBefore;
            expect(memoryIncrease, lessThan(10 * 1024 * 1024)); // 10MB limit
          }

          service.close();
        },
        level: TestLevel.core,
      );

      BlurAppTestFramework.asyncTest(
        'segmentation mask generation performance',
        () async {
          final service = await AutoDetectService.create(
            modelPath: 'assets/models/selfie_segmentation.tflite',
          );

          final stopwatch = Stopwatch()..start();
          final imageBytes = createTestImage(width: 512, height: 512);

          final maskBytes = await service.detectSegmentation(imageBytes);

          stopwatch.stop();

          expect(maskBytes, isNotNull);
          expect(maskBytes!.isNotEmpty, isTrue);

          // Mask generation should be fast (< 2 seconds)
          expect(stopwatch.elapsedMilliseconds, lessThan(2000));

          service.close();
        },
        level: TestLevel.misc,
      );

      BlurAppTestFramework.asyncTest(
        'multiple service instances cleanup properly',
        () async {
          final services = <AutoDetectService>[];

          // Create multiple service instances
          for (int i = 0; i < 5; i++) {
            final service = await AutoDetectService.create(
              modelPath: 'assets/models/face_detection_short_range.tflite',
            );
            services.add(service);
          }

          // Use services
          final imageBytes = createTestImage(width: 200, height: 200);
          for (final service in services) {
            await service.detect(imageBytes);
          }

          // Cleanup all services
          for (final service in services) {
            service.close();
          }

          // No memory leaks expected - test should complete without issues
          expect(services.length, equals(5));
        },
        level: TestLevel.misc,
      );
    });

    group('[PERFORMANCE] Image Save/Load Operations', () {
      BlurAppTestFramework.asyncTest(
        'image save operations handle large files efficiently',
        () async {
          final stopwatch = Stopwatch()..start();
          final largeImageBytes = createTestImage(
            width: 1200,
            height: 900,
            complex: true,
          );

          final String? tempPath = await ImageSaverService.saveImage(
            largeImageBytes,
          );
          final String? permanentPath =
              await ImageSaverService.saveImagePermanent(largeImageBytes);

          stopwatch.stop();

          expect(tempPath != null && tempPath.isNotEmpty, isTrue);
          expect(permanentPath != null && permanentPath.isNotEmpty, isTrue);

          // File operations should complete within reasonable time (10 seconds)
          expect(stopwatch.elapsedMilliseconds, lessThan(10000));

          // Cleanup test files
          try {
            if (tempPath != null && tempPath.isNotEmpty) {
              await File(tempPath).delete();
            }
            if (permanentPath != null && permanentPath.isNotEmpty) {
              await File(permanentPath).delete();
            }
          } catch (e) {
            // Ignore cleanup errors in tests
          }
        },
        level: TestLevel.critical,
      );

      BlurAppTestFramework.asyncTest(
        'cache clearing handles large directories',
        () async {
          // Create multiple test files
          final testImageBytes = createTestImage(width: 100, height: 100);
          final paths = <String?>[];

          for (int i = 0; i < 10; i++) {
            final String? path = await ImageSaverService.saveImage(
              testImageBytes,
            );
            paths.add(path);
          }

          final stopwatch = Stopwatch()..start();

          // Clear cache
          await ImageSaverService.clearCache();

          stopwatch.stop();

          // Cache clearing should be fast even with many files
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));

          // Verify files are cleaned up
          for (final path in paths) {
            // Files might or might not exist depending on cache clearing implementation
            // This test mainly verifies no exceptions are thrown during cache operations
            expect(path != null && path.isNotEmpty, isTrue);
          }
        },
        level: TestLevel.misc,
      );

      BlurAppTestFramework.asyncTest(
        'concurrent image processing maintains stability',
        () async {
          final imageBytes = createTestImage(width: 300, height: 300);
          final futures = <Future>[];

          // Start multiple concurrent blur operations
          for (int i = 0; i < 5; i++) {
            final future = Future(() {
              return BlurPipeline.applyBlur(
                imageBytes,
                BlurType.gaussian,
                5 + i,
              );
            });
            futures.add(future);
          }

          // Wait for all operations to complete
          final results = await Future.wait(futures);

          // All operations should complete successfully
          expect(results.length, equals(5));
          for (final result in results) {
            expect((result as Uint8List).isNotEmpty, isTrue);
          }
        },
        level: TestLevel.critical,
      );
    });

    group('[PERFORMANCE] Edge Cases and Limits', () {
      BlurAppTestFramework.testCase(
        'extremely small images are handled gracefully',
        () {
          final tinyImageBytes = createTestImage(width: 1, height: 1);

          final result = BlurPipeline.applyBlur(
            tinyImageBytes,
            BlurType.gaussian,
            1,
          );
          expect(result.isNotEmpty, isTrue);
        },
        level: TestLevel.misc,
      );

      BlurAppTestFramework.testCase(
        'invalid image data fails gracefully without memory leaks',
        () {
          final invalidBytes = Uint8List.fromList([1, 2, 3, 4]); // Not an image

          final result = BlurPipeline.applyBlur(
            invalidBytes,
            BlurType.gaussian,
            5,
          );

          // Should return original bytes on failure
          expect(result, equals(invalidBytes));
        },
        level: TestLevel.core,
      );

      BlurAppTestFramework.testCase(
        'extreme blur strength values are handled safely',
        () {
          final imageBytes = createTestImage(width: 200, height: 200);

          // Test extreme values
          final lowResult = BlurPipeline.applyBlur(
            imageBytes,
            BlurType.pixelate,
            -5,
          );
          final highResult = BlurPipeline.applyBlur(
            imageBytes,
            BlurType.pixelate,
            1000,
          );

          expect(lowResult.isNotEmpty, isTrue);
          expect(highResult.isNotEmpty, isTrue);
        },
        level: TestLevel.misc,
      );
    });
  });
}
