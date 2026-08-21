import 'package:dartz/dartz.dart';

import '../errors/failures.dart';
import 'api_error_handler.dart';

/// A mixin to provide standardized exception handling for all Repositories.
/// It catches all exceptions, passes them through [ApiErrorHandler], and wraps them
/// in a [Failure], ensuring no raw exceptions ever leak from the domain layer.
mixin RepositoryHelper {
  /// Executes a remote API call, catching all exceptions and converting them to [Failure].
  Future<Either<Failure, T>> safeApiCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } catch (e) {
      final message = ApiErrorHandler.extractErrorMessage(e);
      // Determine failure type based on generic network vs server conditions if needed,
      // but for simplicity, we wrap all in ServerFailure since ApiErrorHandler has normalized it.
      return Left(ServerFailure(message));
    }
  }
}
