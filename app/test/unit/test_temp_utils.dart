import 'dart:io';
import 'dart:typed_data';

/// Utilities for creating and cleaning temporary files in tests.
class TestTempUtils {
  /// Create a file under system temp with [name] and write [bytes]. Returns the File.
  static Future<File> createTempFile(String name, List<int> bytes) async {
    final tmp = Directory.systemTemp;
    final file = File('${tmp.path}/$name');
    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file;
  }

  /// Safely delete a file if it exists (ignore errors).
  static Future<void> safeDelete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
