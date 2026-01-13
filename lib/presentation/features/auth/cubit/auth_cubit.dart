import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/domain/features/auth/usecases/login_usecase.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  })  : _loginUseCase = loginUseCase,
        _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  // Preload cached data on initialization
  Future<void> initialize() async {
    try {
      final cachedResponse = await _localDataSource.getCachedLoginResponse();
      if (cachedResponse != null) {
        emit(AuthLoaded(cachedResponse));
      }
    } catch (e) {
      // Silently fail - no cached data available
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    // Don't emit loading if we already have cached data (to show instant feedback)
    final hasCache = state is AuthLoaded;
    if (!hasCache) {
      emit(const AuthLoading());
    }

    final request = LoginRequestModel(
      username: username.trim(),
      password: password,
    );

    final result = await _loginUseCase(request);

    result.fold(
      (failure) {
        if (failure is NetworkFailure) {
          emit(AuthError('Network error. Please check your connection.'));
        } else if (failure is ServerFailure) {
          emit(AuthError(failure.message ?? 'Login failed. Please try again.'));
        } else {
          emit(AuthError(failure.message ?? 'An unexpected error occurred.'));
        }
      },
      (response) async {
        emit(AuthLoaded(response));
        
        // Check if user is ORGANIZATION_ADMIN and call school names API
        final isOrgAdmin = response.roles.any(
          (role) => role.role == 'ORGANIZATION_ADMIN',
        );
        
        if (isOrgAdmin && response.roles.isNotEmpty) {
          final organizationCode = response.roles.first.organizationCode;
          if (organizationCode.isNotEmpty) {
            try {
              await _remoteDataSource.getSchoolNamesByOrg(
                organizationCode: organizationCode,
                schoolCodes: [], // Empty array as per requirement
                isAdmin: true, // True for ORGANIZATION_ADMIN
                accessToken: response.accessToken,
              );
            } catch (e) {
              // Silently fail - don't block login flow
              // Error is already logged by ApiLogger
            }
          }
        }
      },
    );
  }

  Future<void> loadCachedData() async {
    try {
      final cachedResponse = await _localDataSource.getCachedLoginResponse();
      if (cachedResponse != null) {
        emit(AuthLoaded(cachedResponse));
      }
    } catch (e) {
      emit(AuthError('Failed to load cached data: $e'));
    }
  }

  void logout() {
    emit(const AuthInitial());
  }

  Future<void> clearCache() async {
    try {
      await _localDataSource.clearCache();
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError('Failed to clear cache: $e'));
    }
  }
}
