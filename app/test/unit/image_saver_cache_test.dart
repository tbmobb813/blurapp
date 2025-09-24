import 'dart:io';
// ...existing code...

import 'package:blurapp/services/image_saver_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_framework.dart';
import '../test_setup.dart';
import 'test_gallery_provider.dart';
import 'test_temp_utils.dart';

/// Provider that throws when asked for temporary directory to exercise error
/// handling paths in ImageSaverService.clearCache
class _ErroringTempProvider extends TestGalleryProvider {
  @override
  Future<Directory> getTemporaryDirectory() async {
    throw Exception('simulated getTemporaryDirectory failure');
  }
}

void main() {
  BlurAppTestFramework.testGroup('ImageSaverService cache tests', () {
    BlurAppTestFramework.testCase(
      'clearCache deletes matching temp files and leaves unrelated files',
      () async {
        initTestBootstrap();

        // Ensure we're using TestGalleryProvider which maps temp to system temp
        ImageSaverService.provider = TestGalleryProvider();

  // Create files that should be considered cache
  final f1 = await TestTempUtils.createTempFile('blurred_test1.png', [1, 2, 3]);
  final f2 = await TestTempUtils.createTempFile('blur_export_123.tmp', [4, 5]);
  final f3 = await TestTempUtils.createTempFile('blur_temp_abc.dat', [6]);
  // Unrelated file that should remain
  final other = await TestTempUtils.createTempFile('unrelated_file.txt', [7, 8, 9, 10]);

        // Sanity: files exist
        expect(await f1.exists(), isTrue);
        expect(await f2.exists(), isTrue);
        expect(await f3.exists(), isTrue);
        expect(await other.exists(), isTrue);

        await ImageSaverService.clearCache();

        // Cache files should be deleted
        expect(await f1.exists(), isFalse,
            reason: '${f1.path} should be deleted by clearCache');
        expect(await f2.exists(), isFalse,
            reason: '${f2.path} should be deleted by clearCache');
        expect(await f3.exists(), isFalse,
            reason: '${f3.path} should be deleted by clearCache');

        // Unrelated file should still exist
        expect(await other.exists(), isTrue,
            reason: 'unrelated files should not be deleted');

        // Cleanup
        await TestTempUtils.safeDelete(other);
      },
    );

    BlurAppTestFramework.testCase(
      'getCacheSize returns combined size of matching cache files',
      () async {
        initTestBootstrap();

        ImageSaverService.provider = TestGalleryProvider();
  final a = await TestTempUtils.createTempFile('blurred_size_a.png', List<int>.filled(10, 1));
  final b = await TestTempUtils.createTempFile('blur_export_size_b.tmp', List<int>.filled(20, 2));

  final size = await ImageSaverService.getCacheSize();

  final expected = await a.length() + await b.length();
  expect(size, equals(expected));

        // Cleanup
        await TestTempUtils.safeDelete(a);
        await TestTempUtils.safeDelete(b);
      },
    );

    BlurAppTestFramework.testCase(
      'clearCache handles provider errors gracefully',
      () async {
        initTestBootstrap();

        // Use a provider that throws when asking for temp directory
        ImageSaverService.provider = _ErroringTempProvider();

        // Should not throw
        await ImageSaverService.clearCache();
      },
    );

    BlurAppTestFramework.testCase(
      'getCacheSize is zero after clearCache',
      () async {
        initTestBootstrap();

        ImageSaverService.provider = TestGalleryProvider();
        final a = await TestTempUtils.createTempFile('blurred_after_a.png', List<int>.filled(7, 1));
        final b = await TestTempUtils.createTempFile('blur_export_after_b.tmp', List<int>.filled(3, 2));

        final sizeBefore = await ImageSaverService.getCacheSize();
        expect(sizeBefore, greaterThan(0));

        await ImageSaverService.clearCache();

        final sizeAfter = await ImageSaverService.getCacheSize();
        expect(sizeAfter, equals(0));

        // Cleanup any leftovers (defensive)
        await TestTempUtils.safeDelete(a);
        await TestTempUtils.safeDelete(b);
      },
    );
  });
}
