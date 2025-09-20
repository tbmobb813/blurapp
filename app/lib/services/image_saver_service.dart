import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class ImageSaverService {
  /// Saves image bytes as JPEG or PNG with given quality.
  /// Returns the file path.
  static Future<String> saveImage(Uint8List bytes, {bool asPng = false, int quality = 90}) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/blur_export.${asPng ? 'png' : 'jpg'}';
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image');
    final outBytes = asPng
        ? img.encodePng(image)
        : img.encodeJpg(image, quality: quality);
    final file = File(filePath);
    await file.writeAsBytes(outBytes);
    return filePath;
  }
}
