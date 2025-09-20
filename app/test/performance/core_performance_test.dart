import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:blurapp/features/editor/blur_pipeline.dart';
import 'package:blurapp/services/auto_detect_service.dart';
import '../test_framework.dart';
import '../helpers/performance_test_utils.dart';

void main() {
  BlurAppTestFramework.testGroup(
    'Core Performance Tests',
    () {
      // Helper function to create test images of different sizes
      Uint8List createTestImage(
          {int width = 100, int height = 100, bool complex = false}) {
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

      group('[CORE] Blur Pipeline Performance', () {
        BlurAppTestFramework.testCase(
          'small image gaussian blur performance',
          () {
            final imageBytes = createTestImage(width: 200, height: 200);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 5);
            });

            PerformanceTestUtils.validateExecutionTime(
                timeMeasurement, PerformanceTestUtils.smallImageProcessingLimit,
                context: 'small image gaussian blur');
          },
          level: TestLevel.core,
        );

        BlurAppTestFramework.testCase(
          'medium image pixelate performance',
          () {
            final imageBytes =
                createTestImage(width: 600, height: 400, complex: true);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              return BlurPipeline.applyBlur(imageBytes, BlurType.pixelate, 8);
            });

            PerformanceTestUtils.validateExecutionTime(timeMeasurement,
                PerformanceTestUtils.mediumImageProcessingLimit,
                context: 'medium image pixelate');
          },
          level: TestLevel.critical,
        );

        BlurAppTestFramework.testCase(
          'mosaic blur algorithm performance',
          () {
            final imageBytes =
                createTestImage(width: 400, height: 300, complex: true);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              return BlurPipeline.applyBlur(imageBytes, BlurType.mosaic, 12);
            });

            PerformanceTestUtils.validateExecutionTime(timeMeasurement,
                PerformanceTestUtils.mediumImageProcessingLimit,
                context: 'mosaic blur algorithm');
          },
          level: TestLevel.misc,
        );

        BlurAppTestFramework.testCase(
          'large image memory usage validation',
          () {
            final imageBytes = createTestImage(width: 1200, height: 800);

            final memoryMeasurement =
                PerformanceTestUtils.measureMemoryUsage(() {
              return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 10);
            });

            if (memoryMeasurement.isValid) {
              PerformanceTestUtils.validateMemoryUsage(
                  memoryMeasurement, PerformanceTestUtils.largeImageMemoryLimit,
                  context: 'large image gaussian blur');
            }
          },
          level: TestLevel.critical,
        );

        BlurAppTestFramework.testCase(
          'multiple blur operations stability',
          () {
            final imageBytes = createTestImage(width: 300, height: 300);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              // Perform multiple operations in sequence
              var result = imageBytes;
              for (int i = 0; i < 5; i++) {
                result = BlurPipeline.applyBlur(result, BlurType.gaussian, 3);
              }
              return result;
            });

            // Multiple operations should still complete in reasonable time
            PerformanceTestUtils.validateExecutionTime(timeMeasurement,
                PerformanceTestUtils.mediumImageProcessingLimit,
                context: 'multiple sequential blur operations');
          },
          level: TestLevel.misc,
        );
      });

      group('[CORE] AutoDetectService Performance', () {
        BlurAppTestFramework.asyncTest(
          'face detection suggestion generation performance',
          () async {
            final service = await AutoDetectService.create(
                modelPath: 'assets/models/face_detection_short_range.tflite');

            final imageBytes = createTestImage(width: 400, height: 600);

            final timeMeasurement =
                await PerformanceTestUtils.measureAsyncExecutionTime(() async {
              return await service.detect(imageBytes);
            });

            PerformanceTestUtils.validateExecutionTime(
                timeMeasurement, PerformanceTestUtils.serviceOperationLimit,
                context: 'face detection suggestions');

            service.close();
          },
          level: TestLevel.core,
        );

        BlurAppTestFramework.asyncTest(
          'segmentation mask generation performance',
          () async {
            final service = await AutoDetectService.create(
                modelPath: 'assets/models/selfie_segmentation.tflite');

            final imageBytes =
                createTestImage(width: 512, height: 512, complex: true);

            final timeMeasurement =
                await PerformanceTestUtils.measureAsyncExecutionTime(() async {
              return await service.detectSegmentation(imageBytes);
            });

            PerformanceTestUtils.validateExecutionTime(
                timeMeasurement, PerformanceTestUtils.serviceOperationLimit,
                context: 'segmentation mask generation');

            service.close();
          },
          level: TestLevel.misc,
        );

        BlurAppTestFramework.asyncTest(
          'service memory usage during operations',
          () async {
            final service = await AutoDetectService.create(
                modelPath: 'assets/models/face_detection_short_range.tflite');

            final imageBytes = createTestImage(width: 600, height: 400);

            final memoryMeasurement =
                await PerformanceTestUtils.measureAsyncMemoryUsage(() async {
              final suggestions = await service.detect(imageBytes);
              expect(suggestions.isNotEmpty, isTrue);
            });

            if (memoryMeasurement.isValid) {
              PerformanceTestUtils.validateMemoryUsage(
                  memoryMeasurement, PerformanceTestUtils.serviceMemoryLimit,
                  context: 'AutoDetectService operations');
            }

            service.close();
          },
          level: TestLevel.core,
        );
      });

      group('[CORE] Edge Cases and Stress Tests', () {
        BlurAppTestFramework.testCase(
          'invalid image data handling performance',
          () {
            final invalidBytes = Uint8List.fromList([1, 2, 3, 4]);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              return BlurPipeline.applyBlur(invalidBytes, BlurType.gaussian, 5);
            });

            // Error handling should be fast
            expect(timeMeasurement.milliseconds, lessThan(100));
          },
          level: TestLevel.misc,
        );

        BlurAppTestFramework.testCase(
          'extreme blur strength values performance',
          () {
            final imageBytes = createTestImage(width: 200, height: 200);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              // Test extreme values that should be clamped
              BlurPipeline.applyBlur(imageBytes, BlurType.pixelate, -10);
              BlurPipeline.applyBlur(imageBytes, BlurType.pixelate, 1000);
            });

            // Extreme values should still process quickly due to clamping
            PerformanceTestUtils.validateExecutionTime(
                timeMeasurement, PerformanceTestUtils.smallImageProcessingLimit,
                context: 'extreme blur strength values');
          },
          level: TestLevel.misc,
        );

        BlurAppTestFramework.testCase(
          'minimal size image processing',
          () {
            final tinyImageBytes = createTestImage(width: 1, height: 1);

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              return BlurPipeline.applyBlur(
                  tinyImageBytes, BlurType.gaussian, 1);
            });

            // Tiny images should process very quickly
            expect(timeMeasurement.milliseconds, lessThan(50));
          },
          level: TestLevel.misc,
        );

        BlurAppTestFramework.testCase(
          'concurrent blur operations stress test',
          () {
            final imageBytes = createTestImage(width: 200, height: 200);
            final results = <Uint8List>[];

            final timeMeasurement =
                PerformanceTestUtils.measureExecutionTime(() {
              // Simulate multiple concurrent-like operations
              for (int i = 0; i < 10; i++) {
                final result = BlurPipeline.applyBlur(
                    imageBytes, BlurType.gaussian, i % 5 + 1);
                results.add(result);
              }
            });

            expect(results.length, equals(10));
            for (final result in results) {
              expect(result.isNotEmpty, isTrue);
            }

            // Multiple operations should complete in reasonable time
            PerformanceTestUtils.validateExecutionTime(timeMeasurement,
                PerformanceTestUtils.mediumImageProcessingLimit,
                context: 'concurrent blur operations simulation');
          },
          level: TestLevel.critical,
        );
      });

      group('[CORE] Memory Pressure Tests', () {
        BlurAppTestFramework.testCase(
          'image processing under memory pressure',
          () {
            // Create memory pressure
            final memoryChunks =
                PerformanceTestUtils.createMemoryPressure(sizeInMB: 50);

            try {
              final imageBytes = createTestImage(width: 400, height: 300);

              final timeMeasurement =
                  PerformanceTestUtils.measureExecutionTime(() {
                return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 8);
              });

              // Operations should still complete under memory pressure
              PerformanceTestUtils.validateExecutionTime(
                  timeMeasurement,
                  PerformanceTestUtils.mediumImageProcessingLimit *
                      2, // Allow extra time under pressure
                  context: 'image processing under memory pressure');
            } finally {
              // Always cleanup memory pressure
              PerformanceTestUtils.releaseMemoryPressure(memoryChunks);
            }
          },
          level: TestLevel.misc,
        );
      });
    },
  );
}
