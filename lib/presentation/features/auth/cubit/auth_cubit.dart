import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
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

  /// Mark login as completed only after org + school selection is done.
  Future<void> completeLogin({
    required String selectedOrgCode,
    required String selectedSchoolName,
  }) async {
    if (state is! AuthLoaded) return;
    final loaded = state as AuthLoaded;

    await _localDataSource.cacheLoginResponse(loaded.loginResponse);
    await _localDataSource.saveOrgAndSchoolSelection(
      orgCode: selectedOrgCode,
      schoolName: selectedSchoolName,
    );
  }

  // Preload cached data on initialization
  Future<void> initialize() async {
    try {
      final cachedResponse = await _localDataSource.getCachedLoginResponse();
      if (cachedResponse != null) {
        emit(const AuthInitial());
      }
    } catch (e) {
      // Silently fail - no cached data available
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    final request = LoginRequestModel(
      username: username.trim(),
      password: password,
    );

    final result = await _loginUseCase(request);

    result.fold(
      (failure) {
        // Always surface backend / low-level error messages,
        // instead of inventing UI text here.
        final message = failure.message ?? failure.toString();
        emit(AuthError(message));
      },
      (response) async {
        // Prepare organization codes from roles
        final orgCodes = response.roles
            .map((r) => r.organizationCode)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();

        // 1) Preload organization NAMES using the new API so that the
        //    organization selection screen can show them directly.
        List<String> orgNames = [];
        if (orgCodes.isNotEmpty) {
          try {
            orgNames = await _remoteDataSource.getOrganizationNames(
              organizationCodes: orgCodes,
              accessToken: response.accessToken,
            );
          } catch (_) {
            // If org-names API fails, we silently fall back to showing codes.
            orgNames = [];
          }
        }

        // 2) Prefetch schools for org admin (so next screens feel instant)
        final isOrgAdmin =
            response.roles.any((role) => role.role == 'ORGANIZATION_ADMIN');

        if (!isOrgAdmin || orgCodes.isEmpty) {
          emit(
            AuthLoaded(
              loginResponse: response,
              schoolsByOrg: const {},
              isPrefetchingSchools: false,
              lastErrorMessage: null,
              orgNames: orgNames,
            ),
          );
          return;
        }

        try {
          final results = await Future.wait(
            orgCodes.map(
              (orgCode) => _remoteDataSource.getSchoolNamesByOrg(
                organizationCode: orgCode,
                schoolCodes: const [], // empty list as per requirement
                isAdmin: true,
                accessToken: response.accessToken,
              ),
            ),
          );

          final map = <String, List<String>>{};
          for (var i = 0; i < orgCodes.length; i++) {
            map[orgCodes[i]] = results[i].data;
          }

          emit(
            AuthLoaded(
              loginResponse: response,
              schoolsByOrg: map,
              isPrefetchingSchools: false,
              lastErrorMessage: null,
              orgNames: orgNames,
            ),
          );
        } catch (e) {
          // Don’t block login flow; API logger already prints details.
          // Always surface the raw message coming from the API / Dio.
          emit(
            AuthLoaded(
              loginResponse: response,
              schoolsByOrg: const {},
              isPrefetchingSchools: false,
              lastErrorMessage: e.toString(),
              orgNames: orgNames,
            ),
          );
        }
      },
    );
  }

  Future<void> loadCachedData() async {
    try {
      final cachedResponse = await _localDataSource.getCachedLoginResponse();
      if (cachedResponse != null) {
        emit(AuthLoaded(loginResponse: cachedResponse));
      }
    } catch (e) {
      emit(AuthError('Failed to load cached data: $e'));
    }
  }

  void logout() {
    emit(const AuthInitial());
  }

  /// Professional logout flow:
  /// - call logout API
  /// - clear all local session data
  /// - reset bloc state
  Future<void> logoutSession() async {
    LoginResponseModel? login;
    if (state is AuthLoaded) {
      login = (state as AuthLoaded).loginResponse;
    } else {
      // Fallback: try to read cached login (e.g. after hot restart)
      login = await _localDataSource.getCachedLoginResponse();
    }

    try {
      if (login != null) {
        await _remoteDataSource.logout(
          LogoutRequestModel(
            refreshToken: login.refreshToken,
            userCode: login.userCode,
          ),
        );
      }
    } catch (_) {
      // Even if API logout fails, we still clear local session (session end UX).
    } finally {
      await _localDataSource.clearCache();
      await _localDataSource.clearCredentials();
      emit(const AuthInitial());
    }
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
