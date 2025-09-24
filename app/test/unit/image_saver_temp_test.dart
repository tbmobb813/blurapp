import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:blurapp/services/gallery_provider.dart';
import 'package:blurapp/services/image_saver_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_framework.dart';
import '../test_setup.dart';
import 'test_gallery_provider.dart';
import 'test_temp_utils.dart';

/// Test provider that simulates a failure when attempting to put an image
class _ThrowingProvider extends GalleryProvider {
  final Directory _tmp = Directory.systemTemp;

  @override
  Future<void> putImage(String path, {String? album}) async {
    throw Exception('simulated putImage failure');
  }

  @override
  Future<Directory> getApplicationDocumentsDirectory() async {
    return _tmp;
  }

  @override
  Future<Directory> getTemporaryDirectory() async {
    return _tmp;
  }

  @override
  Future<bool> hasGalleryAccess() async {
    return true;
  }

  @override
  Future<bool> requestGalleryAccess() async {
    return true;
  }
}

void main() {
  BlurAppTestFramework.testGroup('ImageSaverService temp fallback', () {
    BlurAppTestFramework.testCase(
      'saveImage falls back to system temp when gallery save fails',
      () async {
        // Initialize test shims (sets a default TestGalleryProvider)
        initTestBootstrap();

        // Override with a provider that will throw on putImage so saveToGallery
        // returns the temp path and leaves the temp file for inspection.
        ImageSaverService.provider = _ThrowingProvider();

    // Create a valid 1x1 PNG using the image package so decoding/encoding
    // paths in ImageSaverService succeed.
    final Uint8List pngBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 1, height: 1)));

        final String? resultPath = await ImageSaverService.saveImage(
          pngBytes,
          filename: 'test_temp_save',
        );

        // We expect a non-null path and that the file exists in the system temp
        expect(resultPath, isNotNull);
        expect(resultPath!.isNotEmpty, isTrue);

        final file = File(resultPath);
        final exists = await file.exists();
        expect(exists, isTrue, reason: 'Temp file should exist at $resultPath');

        // Cleanup
        await TestTempUtils.safeDelete(file);
      },
    );

    BlurAppTestFramework.testCase(
      'saveImagePermanent writes to documents (system temp) and returns path',
      () async {
        initTestBootstrap();

        // Use the TestGalleryProvider which maps application documents to
        // system temp. This should write a file into system temp and return
        // the file path.
        ImageSaverService.provider = TestGalleryProvider();

    final Uint8List pngBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 1, height: 1)));

        final String? path = await ImageSaverService.saveImagePermanent(
          pngBytes,
          filename: 'test_permanent_save',
          asPng: true,
        );

        expect(path, isNotNull);
        expect(path!.isNotEmpty, isTrue);

        final file = File(path);
        final exists = await file.exists();
        expect(exists, isTrue,
            reason: 'saveImagePermanent should write a file at $path');

        // Cleanup
        await TestTempUtils.safeDelete(file);
      },
    );

    BlurAppTestFramework.testCase(
      'saveImage returns a gallery-like path when provider succeeds',
      () async {
        initTestBootstrap();

        // Set the test provider which simulates successful gallery save
        ImageSaverService.provider = TestGalleryProvider();

    final Uint8List pngBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 1, height: 1)));

        final String? result = await ImageSaverService.saveImage(
          pngBytes,
          filename: 'test_gallery_save',
        );

        // When the provider successfully saves, ImageSaverService returns a
        // gallery-like path 'Gallery/Blur App/<name>.png'
        expect(result, isNotNull);
        expect(result, startsWith('Gallery/Blur App/'));
      },
    );
  });
}
