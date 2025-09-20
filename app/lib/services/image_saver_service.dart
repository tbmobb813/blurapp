import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class ImageSaverService {
  /// Saves image bytes as JPEG or PNG with given quality.
  /// Returns the file path.
  static Future<String> saveImage(Uint8List bytes,
      {bool asPng = false, int quality = 90}) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/blurred_$timestamp.${asPng ? 'png' : 'jpg'}';
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image');
    final outBytes =
        asPng ? img.encodePng(image) : img.encodeJpg(image, quality: quality);
    final file = File(filePath);
    await file.writeAsBytes(outBytes);
    return filePath;
  }

  /// Saves image bytes to documents directory for permanent storage.
  /// Returns the file path.
  static Future<String> saveImagePermanent(Uint8List bytes,
      {bool asPng = false, int quality = 90}) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/blurred_$timestamp.${asPng ? 'png' : 'jpg'}';
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image');
    final outBytes =
        asPng ? img.encodePng(image) : img.encodeJpg(image, quality: quality);
    final file = File(filePath);
    await file.writeAsBytes(outBytes);
    return filePath;
  }

  /// Clears temporary cache files
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        if (file is File &&
            (file.path.contains('blurred_') ||
                file.path.contains('blur_export'))) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore errors when clearing cache
    }
  }
}
