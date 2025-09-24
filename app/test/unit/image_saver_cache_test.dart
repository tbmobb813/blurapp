import 'dart:io';
import 'dart:typed_data';

import 'package:blurapp/services/image_saver_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_framework.dart';
import '../test_setup.dart';
import 'test_gallery_provider.dart';

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

        final tmp = Directory.systemTemp;

        // Create files that should be considered cache
        final f1 = File('${tmp.path}/blurred_test1.png');
        final f2 = File('${tmp.path}/blur_export_123.tmp');
        final f3 = File('${tmp.path}/blur_temp_abc.dat');
        // Unrelated file that should remain
        final other = File('${tmp.path}/unrelated_file.txt');

        await f1.writeAsBytes(Uint8List.fromList([1, 2, 3]));
        await f2.writeAsBytes(Uint8List.fromList([4, 5]));
        await f3.writeAsBytes(Uint8List.fromList([6]));
        await other.writeAsBytes(Uint8List.fromList([7, 8, 9, 10]));

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
        try {
          await other.delete();
        } catch (_) {}
      },
    );

    BlurAppTestFramework.testCase(
      'getCacheSize returns combined size of matching cache files',
      () async {
        initTestBootstrap();

        ImageSaverService.provider = TestGalleryProvider();
        final tmp = Directory.systemTemp;

        final a = File('${tmp.path}/blurred_size_a.png');
        final b = File('${tmp.path}/blur_export_size_b.tmp');

        final bytesA = Uint8List.fromList(List<int>.filled(10, 1));
        final bytesB = Uint8List.fromList(List<int>.filled(20, 2));

        await a.writeAsBytes(bytesA);
        await b.writeAsBytes(bytesB);

        final size = await ImageSaverService.getCacheSize();

        expect(size, equals(bytesA.length + bytesB.length));

        // Cleanup
        try {
          await a.delete();
        } catch (_) {}
        try {
          await b.delete();
        } catch (_) {}
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
        final tmp = Directory.systemTemp;

        final a = File('${tmp.path}/blurred_after_a.png');
        final b = File('${tmp.path}/blur_export_after_b.tmp');

        await a.writeAsBytes(Uint8List.fromList(List<int>.filled(7, 1)));
        await b.writeAsBytes(Uint8List.fromList(List<int>.filled(3, 2)));

        final sizeBefore = await ImageSaverService.getCacheSize();
        expect(sizeBefore, greaterThan(0));

        await ImageSaverService.clearCache();

        final sizeAfter = await ImageSaverService.getCacheSize();
        expect(sizeAfter, equals(0));

        // Cleanup any leftovers (defensive)
        try {
          if (await a.exists()) await a.delete();
        } catch (_) {}
        try {
          if (await b.exists()) await b.delete();
        } catch (_) {}
      },
    );
  });
}
