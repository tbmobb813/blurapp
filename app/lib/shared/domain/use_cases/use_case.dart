import 'package:blurapp/shared/errors/result.dart';

/// Base interface for all use cases
/// Use cases encapsulate business logic and orchestrate repository calls
///
/// Type parameters:
/// - Type: The return type of the use case
/// - Params: The input parameters
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Result<Type>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> extends UseCase<Type, NoParams> {
  @override
  Future<Result<Type>> call(NoParams params);
}

/// Marker class for use cases with no parameters
class NoParams {
  const NoParams();
}
