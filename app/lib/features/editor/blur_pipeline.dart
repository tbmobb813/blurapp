import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum BlurType { gaussian, pixelate, mosaic }

class BlurPipeline {
  static Uint8List applyBlur(
      Uint8List imageBytes, BlurType type, int strength) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      img.Image processedImage;

      switch (type) {
        case BlurType.gaussian:
          processedImage = _gaussianBlur(image, strength);
          break;
        case BlurType.pixelate:
          processedImage = _pixelate(image, strength);
          break;
        case BlurType.mosaic:
          processedImage = _mosaic(image, strength);
          break;
      }

      return Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));
    } catch (e) {
      // If blur fails, return original image
      return imageBytes;
    }
  }

  static img.Image _gaussianBlur(img.Image image, int strength) {
    // Apply Gaussian blur using the image package
    return img.gaussianBlur(image, radius: strength);
  }

  static img.Image _pixelate(img.Image image, int strength) {
    // Create pixelate effect by scaling down and back up
    final blockSize = strength.clamp(1, 32);
    final smallWidth = (image.width / blockSize).round();
    final smallHeight = (image.height / blockSize).round();

    final small = img.copyResize(image,
        width: smallWidth,
        height: smallHeight,
        interpolation: img.Interpolation.nearest);
    return img.copyResize(small,
        width: image.width,
        height: image.height,
        interpolation: img.Interpolation.nearest);
  }

  static img.Image _mosaic(img.Image image, int strength) {
    // Similar to pixelate but with a different algorithm
    final blockSize = strength.clamp(1, 32);
    final result = img.Image.from(image);

    for (int y = 0; y < image.height; y += blockSize) {
      for (int x = 0; x < image.width; x += blockSize) {
        // Get average color of the block
        int r = 0, g = 0, b = 0, count = 0;

        for (int dy = 0; dy < blockSize && y + dy < image.height; dy++) {
          for (int dx = 0; dx < blockSize && x + dx < image.width; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            r += pixel.r.toInt();
            g += pixel.g.toInt();
            b += pixel.b.toInt();
            count++;
          }
        }

        if (count > 0) {
          final avgColor = img.ColorRgb8(r ~/ count, g ~/ count, b ~/ count);

          // Fill the block with average color
          for (int dy = 0; dy < blockSize && y + dy < image.height; dy++) {
            for (int dx = 0; dx < blockSize && x + dx < image.width; dx++) {
              result.setPixel(x + dx, y + dy, avgColor);
            }
          }
        }
      }
    }

    return result;
  }
}
