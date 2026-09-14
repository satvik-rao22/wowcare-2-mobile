import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/network/network_info.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/domain/features/auth/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, LoginResponseModel>> login(
    LoginRequestModel request,
  ) async {
    if (!(await _networkInfo.isConnected)) {
      return const Left(
        NetworkFailure('Network error: please check your connection.'),
      );
    }

    try {
      final response = await _remoteDataSource.login(request);

      return Right(response);
    } catch (e) {
      // Extract error message from API response using common utility
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);

      if (errorMessage.toLowerCase().contains('network error') ||
          errorMessage.toLowerCase().contains('connection')) {
        // No backend response available here, so we keep a minimal
        // technical message instead of inventing a user-facing one.
        return Left(NetworkFailure(errorMessage));
      }

      // For all server-side errors we simply forward the backend message
      // (wrapped inside the exception) so the UI never hardcodes text.
      return Left(ServerFailure(errorMessage));
    }
  }

  @override
  Future<Either<Failure, LoginResponseModel?>> getCachedLoginResponse() async {
    try {
      final cached = await _localDataSource.getCachedLoginResponse();
      return Right(cached);
    } catch (e) {
      return Left(CacheFailure('Failed to get cached login: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAuthCache() async {
    try {
      await _localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async {
    if (!(await _networkInfo.isConnected)) {
      return const Left(
        NetworkFailure('Network error: please check your connection.'),
      );
    }

    try {
      final message = await _remoteDataSource.forgotPassword(email: email);
      return Right(message);
    } catch (e) {
      // Extract error message from API response using common utility
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);

      if (errorMessage.toLowerCase().contains('network error') ||
          errorMessage.toLowerCase().contains('connection')) {
        return Left(NetworkFailure(errorMessage));
      }

      return Left(ServerFailure(errorMessage));
    }
  }
}
