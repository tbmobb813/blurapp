import 'dart:io';

import 'package:blurapp/services/image_saver_service.dart';
import 'package:blurapp/services/gallery_provider.dart';
import 'unit/test_gallery_provider.dart';

/// Test bootstrap executed before running tests. Injects a TestGalleryProvider
/// so tests don't depend on platform plugins (gal, path_provider).
///
/// This also provides a minimal PathProvider bridge so code that defers to
/// the production PathProviderBridge doesn't hit a null and throw a
/// NoSuchMethodError during tests.
void initTestBootstrap() {
  ImageSaverService.provider = TestGalleryProvider();

  // Provide a simple path provider shim used by ProductionGalleryProvider via
  // PathProviderBridge. Tests will use the system temp directory so no
  // platform plugins are required.
  PathProviderBridge.pp = _TestPathProvider();
}

/// Minimal test-only path provider shim. Returns the system temp directory for
/// both temporary and application documents directory calls.
class _TestPathProvider {
  Future<Directory> getTemporaryDirectory() async {
    return Directory.systemTemp;
  }

  Future<Directory> getApplicationDocumentsDirectory() async {
    return Directory.systemTemp;
  }
}
