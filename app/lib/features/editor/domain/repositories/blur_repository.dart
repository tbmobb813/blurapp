import 'package:blurapp/shared/domain/entities/image_data.dart';
import 'package:blurapp/shared/errors/result.dart';
import '../entities/blur_settings.dart';
import '../entities/brush_stroke.dart';

/// Repository for blur processing operations
/// Interface only - implementation in data layer
abstract class BlurRepository {
  /// Apply blur effect to image with mask
  Future<Result<ImageData>> applyBlur({
    required ImageData image,
    required List<BrushStroke> strokes,
    required BlurSettings settings,
    int? workingWidth,
    int? workingHeight,
  });

  /// Generate mask from brush strokes
  Future<Result<List<int>>> generateMask({
    required List<BrushStroke> strokes,
    required int width,
    required int height,
  });

  /// Auto-detect faces and return strokes for masking
  Future<Result<List<BrushStroke>>> detectFaces({
    required ImageData image,
  });

  /// Auto-detect background and return strokes for masking
  Future<Result<List<BrushStroke>>> detectBackground({
    required ImageData image,
  });

  /// Check if GPU acceleration is available
  Future<bool> isGpuAvailable();

  /// Clear any cached blur data
  Future<void> clearCache();
}
