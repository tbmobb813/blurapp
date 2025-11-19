import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_data.freezed.dart';

/// Represents image data in the domain layer
/// Immutable, domain-focused representation
@freezed
class ImageData with _$ImageData {
  const factory ImageData({
    required String id,
    required Uint8List bytes,
    required int width,
    required int height,
    required ImageFormat format,
    DateTime? createdAt,
    String? sourcePath,
  }) = _ImageData;

  const ImageData._();

  /// Get image size in MB
  double get sizeInMB => bytes.length / (1024 * 1024);

  /// Get aspect ratio
  double get aspectRatio => width / height;

  /// Check if image is within memory bounds
  bool get isWithinMemoryBounds {
    const maxBytes = 50 * 1024 * 1024; // 50MB
    return bytes.length <= maxBytes;
  }

  /// Check if image is large
  bool get isLarge {
    const threshold = 2048;
    return width > threshold || height > threshold;
  }

  /// Get total pixels
  int get totalPixels => width * height;
}

/// Supported image formats
enum ImageFormat {
  jpeg,
  png,
  webp;

  String get extension => switch (this) {
        ImageFormat.jpeg => 'jpg',
        ImageFormat.png => 'png',
        ImageFormat.webp => 'webp',
      };

  String get mimeType => switch (this) {
        ImageFormat.jpeg => 'image/jpeg',
        ImageFormat.png => 'image/png',
        ImageFormat.webp => 'image/webp',
      };
}
