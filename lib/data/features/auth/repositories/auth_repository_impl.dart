import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/network/network_info.dart';
import 'package:wowcare/core/util/api_constants.dart';
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
    // Per auth flow requirement: login is not considered complete until
    // org + school selection is completed, so we always perform a fresh login
    // request (no cached auto-login here).
    if (!(await _networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      // Make API call
      final response = await _remoteDataSource.login(request);

      return Right(response);
    } catch (e) {
      if (e.toString().contains('Network error') ||
          e.toString().contains('connection')) {
        return const Left(NetworkFailure('Network error occurred'));
      } else if (e.toString().contains('401') ||
          e.toString().contains('Invalid credentials')) {
        return const Left(ServerFailure('Invalid username or password'));
      } else {
        return Left(ServerFailure(e.toString()));
      }
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
}
