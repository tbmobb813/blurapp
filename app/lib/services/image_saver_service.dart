import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';

/// Service for saving images to device gallery and managing cache
/// 
/// Handles:
/// - Gallery permissions
/// - High-quality image export
/// - Temporary file management
/// - Error handling and user feedback
class ImageSaverService {
  static const String _tag = 'ImageSaverService';

  /// Saves image bytes to device gallery
  /// 
  /// [bytes] - Image data as PNG or JPEG bytes
  /// [filename] - Optional custom filename (without extension)
  /// [quality] - JPEG quality (0-100), ignored for PNG
  /// 
  /// Returns the gallery path or null if failed
  static Future<String?> saveToGallery(
    Uint8List bytes, {
    String? filename,
    int quality = 95,
  }) async {
    try {
      // Check and request permissions
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) {
        debugPrint('$_tag: Gallery permission denied');
        return null;
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = filename ?? 'blurred_$timestamp';
      
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$name.png';
      final tempFile = File(tempPath);
      
      // Process and write image
      Uint8List processedBytes;
      if (_isPng(bytes)) {
        // Keep PNG as-is for lossless quality
        processedBytes = bytes;
      } else {
        // Re-encode JPEG/other formats as PNG for best quality
        final image = img.decodeImage(bytes);
        if (image == null) {
          debugPrint('$_tag: Failed to decode image');
          return null;
        }
        processedBytes = Uint8List.fromList(img.encodePng(image));
      }
      
      await tempFile.writeAsBytes(processedBytes);
      
      // Save to gallery
      await Gal.putImage(tempPath, album: 'Blur App');
      
      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('$_tag: Failed to clean up temp file: $e');
      }
      
      debugPrint('$_tag: Successfully saved image to gallery');
      return 'Gallery/Blur App/$name.png';
      
    } catch (e) {
      debugPrint('$_tag: Error saving to gallery: $e');
      return null;
    }
  }

  /// Saves image bytes to app documents (for sharing/backup)
  /// 
  /// Returns the file path or null if failed
  static Future<String?> saveToDocuments(
    Uint8List bytes, {
    String? filename,
    bool asPng = true,
    int quality = 95,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = filename ?? 'blurred_$timestamp';
      final extension = asPng ? 'png' : 'jpg';
      final filePath = '${dir.path}/$name.$extension';
      
      // Process image
      Uint8List processedBytes;
      if (asPng) {
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception('Invalid image data');
        processedBytes = Uint8List.fromList(img.encodePng(image));
      } else {
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception('Invalid image data');
        processedBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      }
      
      final file = File(filePath);
      await file.writeAsBytes(processedBytes);
      
      debugPrint('$_tag: Saved to documents: $filePath');
      return filePath;
      
    } catch (e) {
      debugPrint('$_tag: Error saving to documents: $e');
      return null;
    }
  }

  /// Checks if the app has gallery save permission
  static Future<bool> hasGalleryPermission() async {
    try {
      return await Gal.hasAccess();
    } catch (e) {
      debugPrint('$_tag: Error checking gallery permission: $e');
      return false;
    }
  }

  /// Requests gallery save permission
  static Future<bool> _requestGalleryPermission() async {
    try {
      // Check if already has permission
      if (await Gal.hasAccess()) {
        return true;
      }
      
      // Request permission
      await Gal.requestAccess();
      return await Gal.hasAccess();
      
    } catch (e) {
      debugPrint('$_tag: Error requesting gallery permission: $e');
      return false;
    }
  }

  /// Clears temporary cache files
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File &&
            (file.path.contains('blurred_') ||
                file.path.contains('blur_export') ||
                file.path.contains('blur_temp'))) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            debugPrint('$_tag: Failed to delete cache file: ${file.path}');
          }
        }
      }
      
      debugPrint('$_tag: Cleared $deletedCount cache files');
    } catch (e) {
      debugPrint('$_tag: Error clearing cache: $e');
    }
  }

  /// Gets cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      int totalSize = 0;
      
      for (final file in files) {
        if (file is File &&
            (file.path.contains('blurred_') ||
                file.path.contains('blur_export') ||
                file.path.contains('blur_temp'))) {
          try {
            final stat = await file.stat();
            totalSize += stat.size;
          } catch (e) {
            // Ignore individual file stat errors
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('$_tag: Error calculating cache size: $e');
      return 0;
    }
  }

  // Private helper methods

  static bool _isPng(Uint8List bytes) {
    if (bytes.length < 8) return false;
    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    return bytes[0] == 0x89 &&
           bytes[1] == 0x50 &&
           bytes[2] == 0x4E &&
           bytes[3] == 0x47;
  }
}
