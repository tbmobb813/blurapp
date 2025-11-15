import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Base class for all failures in the application
/// Using Freezed for immutable, pattern-matchable errors
@freezed
class Failure with _$Failure {
  const factory Failure.imageLoad({
    required String message,
    Object? error,
  }) = ImageLoadFailure;

  const factory Failure.imageProcess({
    required String message,
    Object? error,
  }) = ImageProcessFailure;

  const factory Failure.imageSave({
    required String message,
    Object? error,
  }) = ImageSaveFailure;

  const factory Failure.permission({
    required String message,
    required String permissionType,
  }) = PermissionFailure;

  const factory Failure.modelLoad({
    required String message,
    required String modelPath,
  }) = ModelLoadFailure;

  const factory Failure.outOfMemory({
    required String message,
    int? requiredBytes,
    int? availableBytes,
  }) = OutOfMemoryFailure;

  const factory Failure.unknown({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnknownFailure;
}

/// Extension to get user-friendly error messages
extension FailureX on Failure {
  String get userMessage => when(
        imageLoad: (msg, _) => 'Could not load image. Please try another.',
        imageProcess: (msg, _) => 'Failed to process image. Please try again.',
        imageSave: (msg, _) => 'Could not save image. Check permissions.',
        permission: (msg, type) =>
            'Permission denied: $type. Please grant access in settings.',
        modelLoad: (msg, path) => 'AI model failed to load. Using fallback.',
        outOfMemory: (msg, required, available) =>
            'Image too large. Try a smaller image.',
        unknown: (msg, _, __) => 'An unexpected error occurred.',
      );

  String get technicalMessage => when(
        imageLoad: (msg, error) => 'ImageLoad: $msg${error != null ? " - $error" : ""}',
        imageProcess: (msg, error) =>
            'ImageProcess: $msg${error != null ? " - $error" : ""}',
        imageSave: (msg, error) =>
            'ImageSave: $msg${error != null ? " - $error" : ""}',
        permission: (msg, type) => 'Permission: $msg (type: $type)',
        modelLoad: (msg, path) => 'ModelLoad: $msg (path: $path)',
        outOfMemory: (msg, required, available) =>
            'OOM: $msg (required: $required, available: $available)',
        unknown: (msg, error, trace) =>
            'Unknown: $msg${error != null ? " - $error" : ""}',
      );
}
