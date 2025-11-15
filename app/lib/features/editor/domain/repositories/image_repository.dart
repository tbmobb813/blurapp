import 'package:blurapp/shared/domain/entities/image_data.dart';
import 'package:blurapp/shared/errors/result.dart';

/// Repository for image operations
/// This is an interface - implementations go in data layer
abstract class ImageRepository {
  /// Load image from file path
  Future<Result<ImageData>> loadImage(String path);

  /// Load image from bytes
  Future<Result<ImageData>> loadImageFromBytes(List<int> bytes);

  /// Save image to device
  Future<Result<String>> saveImage({
    required ImageData image,
    required String fileName,
    bool saveToGallery = true,
  });

  /// Resize image to fit within dimensions
  Future<Result<ImageData>> resizeImage({
    required ImageData image,
    required int maxWidth,
    required int maxHeight,
  });

  /// Get image dimensions without loading full image
  Future<Result<ImageDimensions>> getImageDimensions(String path);

  /// Check if image is within memory constraints
  Future<Result<bool>> validateImageSize(String path);
}

/// Image dimensions value object
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({
    required this.width,
    required this.height,
  });

  double get aspectRatio => width / height;
  int get totalPixels => width * height;
}
