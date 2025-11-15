import 'package:freezed_annotation/freezed_annotation.dart';
import 'failures.dart';

part 'result.freezed.dart';

/// Result type for functional error handling
/// Represents either a Success with value T or a Failure with error
@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure error) = ResultFailure<T>;

  const Result._();

  /// Check if result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is ResultFailure<T>;

  /// Get value or null
  T? get valueOrNull => when(
        success: (value) => value,
        failure: (_) => null,
      );

  /// Get error or null
  Failure? get errorOrNull => when(
        success: (_) => null,
        failure: (error) => error,
      );

  /// Transform success value
  Result<R> map<R>(R Function(T value) transform) => when(
        success: (value) {
          try {
            return Result.success(transform(value));
          } catch (e, stack) {
            return Result.failure(
              Failure.unknown(
                message: 'Transformation failed',
                error: e,
                stackTrace: stack,
              ),
            );
          }
        },
        failure: (error) => Result.failure(error),
      );

  /// Transform to async result
  Future<Result<R>> mapAsync<R>(
    Future<R> Function(T value) transform,
  ) async =>
      when(
        success: (value) async {
          try {
            final result = await transform(value);
            return Result.success(result);
          } catch (e, stack) {
            return Result.failure(
              Failure.unknown(
                message: 'Async transformation failed',
                error: e,
                stackTrace: stack,
              ),
            );
          }
        },
        failure: (error) => Result.failure(error),
      );

  /// Flat map for chaining operations
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => when(
        success: (value) {
          try {
            return transform(value);
          } catch (e, stack) {
            return Result.failure(
              Failure.unknown(
                message: 'FlatMap failed',
                error: e,
                stackTrace: stack,
              ),
            );
          }
        },
        failure: (error) => Result.failure(error),
      );

  /// Get value or throw
  T getOrThrow() => when(
        success: (value) => value,
        failure: (error) => throw Exception(error.technicalMessage),
      );

  /// Get value or default
  T getOrElse(T defaultValue) => when(
        success: (value) => value,
        failure: (_) => defaultValue,
      );

  /// Get value or compute default
  T getOrElseLazy(T Function() defaultValue) => when(
        success: (value) => value,
        failure: (_) => defaultValue(),
      );
}

/// Extensions for Future<Result<T>>
extension FutureResultX<T> on Future<Result<T>> {
  /// Map future result
  Future<Result<R>> map<R>(R Function(T value) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Flat map future result
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    final result = await this;
    return result.when(
      success: (value) => transform(value),
      failure: (error) => Result.failure(error),
    );
  }
}
