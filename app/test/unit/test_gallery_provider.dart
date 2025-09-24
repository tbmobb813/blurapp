import 'dart:io';

import 'package:blurapp/services/gallery_provider.dart';

/// Simple test provider that writes to system temp and simulates gallery calls
class TestGalleryProvider extends GalleryProvider {
  final Directory _tmp = Directory.systemTemp;

  @override
  Future<void> putImage(String path, {String? album}) async {
    // simulate success; do nothing
    return;
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
