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
    String? selectedSchoolCode,
  }) async {
    if (state is AuthLoaded) {
      final loaded = state as AuthLoaded;
      await _localDataSource.cacheLoginResponse(loaded.loginResponse);
    }
    await _localDataSource.saveOrgAndSchoolSelection(
      orgCode: selectedOrgCode,
      schoolName: selectedSchoolName,
      schoolCode: selectedSchoolCode,
    );
  }

  /// Set selected org/school (e.g. when switching organisation from Dashboard).
  Future<void> setSelectedOrgAndSchool({
    required String organizationCode,
    required String schoolCode,
    String? schoolName,
  }) async {
    await _localDataSource.setSelectedOrgAndSchool(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      schoolName: schoolName,
    );
  }

  /// Updates backend login-context (last org/school) via PATCH. Call when user
  /// selects org (school can be empty) or school. Non-blocking: failures are
  /// ignored so navigation is not blocked.
  Future<void> updateLoginContext({
    required String lastLoginOrganizationCode,
    required String lastLoginSchoolCode,
  }) async {
    String? accessToken;
    if (state is AuthLoaded) {
      accessToken = (state as AuthLoaded).loginResponse.accessToken;
    } else {
      final cached = await _localDataSource.getCachedLoginResponse();
      accessToken = cached?.accessToken;
    }
    if (accessToken == null || accessToken.isEmpty) return;
    try {
      await _remoteDataSource.patchLoginContext(
        accessToken: accessToken,
        lastLoginOrganizationCode: lastLoginOrganizationCode,
        lastLoginSchoolCode: lastLoginSchoolCode,
      );
    } catch (_) {
      // Non-blocking: do not block navigation if PATCH fails.
    }
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
        // Persist latest login response (tokens, user, roles) for future app launches.
        try {
          await _localDataSource.cacheLoginResponse(response);
        } catch (_) {
          // Non-fatal: if caching fails, login can still proceed.
        }

        // Immediately fetch login-context with this token so backend can tell
        // us which org/school (last school) should be active for this user.
        bool hasLastSchoolFromContext = false;
        String? redirectUrl;
        try {
          final contextData = await _remoteDataSource.getLoginContext(
            accessToken: response.accessToken,
          );
          await _localDataSource.saveLoginContext(contextData);
          hasLastSchoolFromContext =
              await _localDataSource.saveOrgAndSchoolFromContext(contextData);
          
          // When orgCode or schoolCode is null (or both), use redirectUrl to decide where to open.
          final String orgCode = ((contextData['LastLoginOrganizationCode'] as String?)?.trim ?? '').toString();
          final String schoolCode = ((contextData['LastLoginSchoolCode'] as String?)?.trim ?? '').toString();
          if (orgCode.isEmpty || schoolCode.isEmpty) {
            final rawRedirect = contextData['redirectUrl'];
            redirectUrl = rawRedirect is String ? rawRedirect.trim() : null;
            // Save orgCode only if present (needed when redirect is select-school)
            if (orgCode.isNotEmpty) {
              await _localDataSource.setSelectedOrgAndSchool(
                organizationCode: orgCode,
                schoolCode: schoolCode,
                schoolName: '',
              );
            }
          }
        } catch (_) {
          // Do not block login if context API fails; it will also be retried on app start.
        }

        // Only login + login-context during login flow. No school prefetch.
        emit(
          AuthLoaded(
            loginResponse: response,
            schoolsByOrg: const {},
            isPrefetchingSchools: false,
            lastErrorMessage: null,
            hasLastSchoolFromContext: hasLastSchoolFromContext,
            redirectUrl: redirectUrl,
          ),
        );
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
