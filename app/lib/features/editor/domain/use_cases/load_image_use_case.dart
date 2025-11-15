import 'package:blurapp/shared/domain/entities/image_data.dart';
import 'package:blurapp/shared/domain/use_cases/use_case.dart';
import 'package:blurapp/shared/errors/result.dart';
import '../repositories/image_repository.dart';

/// Use case for loading an image
class LoadImageUseCase extends UseCase<ImageData, LoadImageParams> {
  final ImageRepository _repository;

  LoadImageUseCase(this._repository);

  @override
  Future<Result<ImageData>> call(LoadImageParams params) async {
    // Step 1: Validate image size before loading
    final validationResult = await _repository.validateImageSize(params.path);

    if (validationResult.isFailure) {
      return Result.failure(validationResult.errorOrNull!);
    }

    if (validationResult.valueOrNull == false) {
      return Result.failure(
        Failure.outOfMemory(
          message: 'Image exceeds memory constraints',
        ),
      );
    }

    // Step 2: Load the image
    final loadResult = await _repository.loadImage(params.path);

    if (loadResult.isFailure) {
      return loadResult;
    }

    final image = loadResult.valueOrNull!;

    // Step 3: Resize if needed
    if (params.maxWidth != null || params.maxHeight != null) {
      return await _repository.resizeImage(
        image: image,
        maxWidth: params.maxWidth ?? image.width,
        maxHeight: params.maxHeight ?? image.height,
      );
    }

    return Result.success(image);
  }
}

/// Parameters for LoadImageUseCase
class LoadImageParams {
  final String path;
  final int? maxWidth;
  final int? maxHeight;

  const LoadImageParams({
    required this.path,
    this.maxWidth,
    this.maxHeight,
  });
}
