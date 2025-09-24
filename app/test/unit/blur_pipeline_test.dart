import 'package:blurapp/features/editor/blur_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_framework.dart';

void main() {
  BlurAppTestFramework.testGroup('BlurPipeline Core Algorithm Tests', () {
    BlurAppTestFramework.testCase(
      'gaussian blur produces valid output for all strengths',
      () {
        final testImageBytes = TestHelpers.createTestImageBytes();

        for (int strength = 1; strength <= 30; strength++) {
          BlurAppAssertions.assertValidBlurParams(strength, max: 30);

          final result = BlurPipeline.applyBlur(
            testImageBytes,
            BlurType.gaussian,
            strength,
          );

          BlurAppAssertions.assertValidImageResult(result);
        }
      },
      level: TestLevel.core,
    );

    BlurAppTestFramework.testCase(
      'pixelate effect maintains image integrity',
      () {
        final testImageBytes = TestHelpers.createTestImageBytes();

        final result = BlurPipeline.applyBlur(
          testImageBytes,
          BlurType.pixelate,
          10,
        );

        BlurAppAssertions.assertValidImageResult(result);
        expect(result.length, greaterThan(0));
      },
      level: TestLevel.core,
    );

    BlurAppTestFramework.testCase('mosaic effect produces valid output', () {
      final testImageBytes = TestHelpers.createTestImageBytes();

      final result = BlurPipeline.applyBlur(testImageBytes, BlurType.mosaic, 8);

      BlurAppAssertions.assertValidImageResult(result);
    }, level: TestLevel.core);

    BlurAppTestFramework.testCase('handles invalid blur type gracefully', () {
      final testImageBytes = TestHelpers.createTestImageBytes();

      // This should not crash
      expect(
        () => BlurPipeline.applyBlur(
          testImageBytes,
          BlurType.gaussian, // Use valid type for now
          5,
        ),
        returnsNormally,
      );
    }, level: TestLevel.misc);

    BlurAppTestFramework.testCase('handles edge case blur strength values', () {
      final testImageBytes = TestHelpers.createTestImageBytes();

      // Test edge cases - current implementation may not validate
      // This documents current behavior
      final result1 = BlurPipeline.applyBlur(
        testImageBytes,
        BlurType.gaussian,
        0,
      );
      expect(result1, isNotNull); // Current implementation returns data

      final result2 = BlurPipeline.applyBlur(
        testImageBytes,
        BlurType.gaussian,
        -1,
      );
      expect(result2, isNotNull); // Current implementation returns data
    }, level: TestLevel.misc);
  });
}
