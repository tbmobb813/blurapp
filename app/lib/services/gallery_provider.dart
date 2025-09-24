import 'dart:io';

/// Abstract provider for gallery/path operations so we can inject test doubles
abstract class GalleryProvider {
  /// Check if the app has gallery access (platform-specific)
  Future<bool> hasGalleryAccess();

  /// Request gallery access from the platform (permissions UI or platform API)
  Future<bool> requestGalleryAccess();

  /// Save an image file path to the gallery/album (platform API)
  Future<void> putImage(String path, {String? album});

  /// Get temporary directory (wrapper around path_provider)
  Future<Directory> getTemporaryDirectory();

  /// Get application documents directory
  Future<Directory> getApplicationDocumentsDirectory();

  /// Optional hook for provider-specific cleanup
  // Optional cleanup hook (implementations may override)
  Future<void> dispose() async {}
}

/// Production provider that uses Gal and path_provider
class ProductionGalleryProvider extends GalleryProvider {
  ProductionGalleryProvider();

  @override
  Future<bool> hasGalleryAccess() async {
    try {
      // Defer import to runtime to avoid test-time missing plugin errors
      final gal = await _loadGal();
      return await gal.hasAccess();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestGalleryAccess() async {
    try {
      final gal = await _loadGal();
      await gal.requestAccess();
      return await gal.hasAccess();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> putImage(String path, {String? album}) async {
    final gal = await _loadGal();
    await gal.putImage(path, album: album);
  }

  @override
  Future<Directory> getTemporaryDirectory() async {
    // path_provider is assumed available in production
    final pp = await _loadPathProvider();
    return await pp.getTemporaryDirectory();
  }

  @override
  Future<Directory> getApplicationDocumentsDirectory() async {
    final pp = await _loadPathProvider();
    return await pp.getApplicationDocumentsDirectory();
  }

  // Lazy dynamic imports to avoid test-time plugin resolution failures
  Future<dynamic> _loadGal() async {
    // ignore: avoid_dynamic_calls
    return await Future.value(GalBridge.gal);
  }

  Future<dynamic> _loadPathProvider() async {
    // ignore: avoid_dynamic_calls
    return await Future.value(PathProviderBridge.pp);
  }
}

// Bridges used to defer imports. Tests can override these bridges if needed.
// These are simple holders to avoid importing Gal/path_provider at top-level.
class GalBridge {
  static dynamic gal;
}

class PathProviderBridge {
  static dynamic pp;
}
