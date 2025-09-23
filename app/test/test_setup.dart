import 'package:blurapp/services/image_saver_service.dart';
import 'unit/test_gallery_provider.dart';

/// Test bootstrap executed before running tests. Injects a TestGalleryProvider
/// so tests don't depend on platform plugins (gal, path_provider).
void initTestBootstrap() {
  ImageSaverService.provider = TestGalleryProvider();
}
