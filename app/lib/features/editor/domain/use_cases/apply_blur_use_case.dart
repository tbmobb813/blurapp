import 'package:blurapp/shared/domain/entities/image_data.dart';
import 'package:blurapp/shared/domain/use_cases/use_case.dart';
import 'package:blurapp/shared/errors/result.dart';
import '../entities/blur_settings.dart';
import '../entities/brush_stroke.dart';
import '../repositories/blur_repository.dart';

/// Use case for applying blur effect to an image
class ApplyBlurUseCase extends UseCase<ImageData, ApplyBlurParams> {
  final BlurRepository _repository;

  ApplyBlurUseCase(this._repository);

  @override
  Future<Result<ImageData>> call(ApplyBlurParams params) async {
    // Validate inputs
    if (params.strokes.isEmpty) {
      return Result.failure(
        Failure.imageProcess(
          message: 'No brush strokes provided',
        ),
      );
    }

    if (!params.settings.isValid) {
      return Result.failure(
        Failure.imageProcess(
          message: 'Invalid blur settings',
        ),
      );
    }

    // Apply blur
    final result = await _repository.applyBlur(
      image: params.image,
      strokes: params.strokes,
      settings: params.settings,
      workingWidth: params.workingWidth,
      workingHeight: params.workingHeight,
    );

    return result;
  }
}

/// Parameters for ApplyBlurUseCase
class ApplyBlurParams {
  final ImageData image;
  final List<BrushStroke> strokes;
  final BlurSettings settings;
  final int? workingWidth;
  final int? workingHeight;

  const ApplyBlurParams({
    required this.image,
    required this.strokes,
    required this.settings,
    this.workingWidth,
    this.workingHeight,
  });
}
