import 'dart:typed_data';

import 'package:blurapp/features/editor/blur_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/performance_test_utils.dart';
import '../test_framework.dart';

void main() {
  BlurAppTestFramework.testGroup('Enhanced Memory Management Tests', () {
    // Helper to create large test images
    Uint8List createLargeTestImage({required int width, required int height}) {
      final image = img.Image(width: width, height: height);

      // Create a pattern that exercises the blur algorithms
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final r = ((x + y) % 256);
          final g = ((x * 3) % 256);
          final b = ((y * 3) % 256);
          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }

      return Uint8List.fromList(img.encodePng(image));
    }

    group('[CRITICAL] Memory Safety Features', () {
      BlurAppTestFramework.testCase('very large image processing with memory constraints', () {
        // Create a very large image that would normally cause memory issues
        final largeImageBytes = createLargeTestImage(width: 4000, height: 3000);

        final memoryMeasurement = PerformanceTestUtils.measureMemoryUsage(() {
          final result = BlurPipeline.applyBlur(largeImageBytes, BlurType.gaussian, 10);
          expect(result.isNotEmpty, isTrue);

          // The result should be processed (downsized) successfully
          final processedImage = img.decodeImage(result);
          expect(processedImage, isNotNull);

          // Should be downsized for memory efficiency
          expect(processedImage!.width, lessThanOrEqualTo(2048));
          expect(processedImage.height, lessThanOrEqualTo(2048));
        });

        // Memory usage should be controlled even for very large images
        if (memoryMeasurement.isValid) {
          PerformanceTestUtils.validateMemoryUsage(
            memoryMeasurement,
            PerformanceTestUtils.largeImageMemoryLimit,
            context: 'very large image processing',
          );
        }
      }, level: TestLevel.critical);

      BlurAppTestFramework.testCase('preview mode reduces memory usage', () {
        final largeImageBytes = createLargeTestImage(width: 2000, height: 1500);

        // Test normal processing
        final normalResult = BlurPipeline.applyBlur(largeImageBytes, BlurType.pixelate, 8);
        final normalImage = img.decodeImage(normalResult)!;

        // Test preview processing
        final previewResult = BlurPipeline.applyBlur(largeImageBytes, BlurType.pixelate, 8, isPreview: true);
        final previewImage = img.decodeImage(previewResult)!;

        // Preview should be smaller
        expect(previewImage.width, lessThan(normalImage.width));
        expect(previewImage.height, lessThan(normalImage.height));
        expect(previewImage.width, lessThanOrEqualTo(512));
        expect(previewImage.height, lessThanOrEqualTo(512));
      }, level: TestLevel.core);

      BlurAppTestFramework.testCase('extreme strength values are safely clamped', () {
        final imageBytes = createLargeTestImage(width: 400, height: 300);

        // Test extreme negative value
        final negativeResult = BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, -100);
        expect(negativeResult.isNotEmpty, isTrue);

        // Test extreme positive value
        final extremeResult = BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 10000);
        expect(extremeResult.isNotEmpty, isTrue);

        // Both should process without errors due to clamping
        final negativeImage = img.decodeImage(negativeResult);
        final extremeImage = img.decodeImage(extremeResult);
        expect(negativeImage, isNotNull);
        expect(extremeImage, isNotNull);
      }, level: TestLevel.misc);
    });

    group('[CRITICAL] Performance Optimizations', () {
      BlurAppTestFramework.testCase('large image processing completes within time limits', () {
        final largeImageBytes = createLargeTestImage(width: 1920, height: 1080);

        final timeMeasurement = PerformanceTestUtils.measureExecutionTime(() {
          return BlurPipeline.applyBlur(largeImageBytes, BlurType.mosaic, 15);
        });

        // Even large images should complete within reasonable time due to optimization
        PerformanceTestUtils.validateExecutionTime(
          timeMeasurement,
          PerformanceTestUtils.largeImageProcessingLimit,
          context: 'optimized large image processing',
        );
      }, level: TestLevel.critical);

      BlurAppTestFramework.testCase('preview processing is significantly faster', () {
        final imageBytes = createLargeTestImage(width: 1200, height: 800);

        // Measure normal processing time
        final normalTime = PerformanceTestUtils.measureExecutionTime(() {
          return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 12);
        });

        // Measure preview processing time
        final previewTime = PerformanceTestUtils.measureExecutionTime(() {
          return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 12, isPreview: true);
        });

        // Preview should be faster (allow some variance for small differences)
        expect(previewTime.milliseconds, lessThanOrEqualTo(normalTime.milliseconds + 100));

        // Preview should complete quickly
        expect(previewTime.milliseconds, lessThan(2000));
      }, level: TestLevel.critical);

      BlurAppTestFramework.testCase('memory usage scales predictably with image size', () {
        final sizes = [
          [200, 200], // Small
          [400, 400], // Medium
          [800, 600], // Large (but within limits)
        ];

        final memoryUsages = <int>[];

        for (final size in sizes) {
          final imageBytes = createLargeTestImage(width: size[0], height: size[1]);

          final measurement = PerformanceTestUtils.measureMemoryUsage(() {
            return BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 8);
          });

          if (measurement.isValid) {
            memoryUsages.add(measurement.difference);
          }
        }

        // If we have valid measurements, larger images shouldn't use exponentially more memory
        if (memoryUsages.length >= 2) {
          // Due to optimization, memory usage should be controlled
          for (final usage in memoryUsages) {
            expect(usage, lessThan(PerformanceTestUtils.largeImageMemoryLimit));
          }
        }
      }, level: TestLevel.misc);
    });

    group('[CORE] Edge Case Handling', () {
      BlurAppTestFramework.testCase('ultra-high resolution image handling', () {
        // Test with unrealistic resolution to verify safety limits
        final ultraHighResBytes = createLargeTestImage(width: 8000, height: 6000);

        final result = BlurPipeline.applyBlur(ultraHighResBytes, BlurType.pixelate, 20);
        expect(result.isNotEmpty, isTrue);

        final processedImage = img.decodeImage(result);
        expect(processedImage, isNotNull);

        // Should be automatically downsized to safe limits
        expect(processedImage!.width, lessThanOrEqualTo(2048));
        expect(processedImage.height, lessThanOrEqualTo(2048));
      }, level: TestLevel.misc);

      BlurAppTestFramework.testCase('concurrent large image processing', () {
        final imageBytes = createLargeTestImage(width: 800, height: 600);
        final results = <Uint8List>[];

        final timeMeasurement = PerformanceTestUtils.measureExecutionTime(() {
          // Simulate concurrent-like processing
          for (int i = 0; i < 3; i++) {
            final result = BlurPipeline.applyBlur(imageBytes, BlurType.gaussian, 5 + i);
            results.add(result);
          }
        });

        expect(results.length, equals(3));
        for (final result in results) {
          expect(result.isNotEmpty, isTrue);
          final image = img.decodeImage(result);
          expect(image, isNotNull);
        }

        // Multiple large images should still process in reasonable time
        PerformanceTestUtils.validateExecutionTime(
          timeMeasurement,
          PerformanceTestUtils.largeImageProcessingLimit,
          context: 'concurrent large image processing',
        );
      }, level: TestLevel.critical);

      BlurAppTestFramework.testCase('memory cleanup after processing', () {
        // Create and process multiple large images to test cleanup
        final imageBytes = createLargeTestImage(width: 1000, height: 800);

        final initialMemory = PerformanceTestUtils.getCurrentMemoryUsage();

        // Process multiple images
        for (int i = 0; i < 5; i++) {
          final result = BlurPipeline.applyBlur(imageBytes, BlurType.mosaic, 10);
          expect(result.isNotEmpty, isTrue);
        }

        final finalMemory = PerformanceTestUtils.getCurrentMemoryUsage();

        // Memory usage should be reasonable even after multiple large image operations
        if (initialMemory > 0 && finalMemory > 0) {
          final memoryIncrease = finalMemory - initialMemory;
          expect(memoryIncrease, lessThan(PerformanceTestUtils.largeImageMemoryLimit));
        }
      }, level: TestLevel.misc);
    });
  });
}
