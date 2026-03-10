import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/domain/features/auth/usecases/login_usecase.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/data/static/static_school_catalog.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';

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
  /// selects org (schoolCode null) or school. Sends null for empty values.
  /// Non-blocking: failures are ignored so navigation is not blocked.
  Future<void> updateLoginContext({
    required String? lastLoginOrganizationCode,
    required String? lastLoginSchoolCode,
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
        // When app starts and we already have a cached login response,
        // immediately expose it as AuthLoaded so org/school selection
        // screens (and others) can render without an extra loading state.
        emit(
          AuthLoaded(
            loginResponse: cachedResponse,
            schoolsByOrg: const <String, List<Map<String, String>>>{},
            isPrefetchingSchools: false,
            lastErrorMessage: null,
            orgNames: const [],
            hasLastSchoolFromContext: false,
            redirectUrl: null,
          ),
        );
      } else {
        emit(const AuthInitial());
      }
    } catch (e) {
      // Silently fall back to initial state if anything goes wrong.
      emit(const AuthInitial());
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
          final String orgCode = (contextData['LastLoginOrganizationCode'] as String?)?.trim() ?? '';
          final String schoolCode = (contextData['LastLoginSchoolCode'] as String?)?.trim() ?? '';
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

          // After login-context, resolve staffCode for this user (if they have a staff profile)
          // using `/api/v1/staff/code?userCode=...&organizationCode=...&schoolCode=...`.
          if (orgCode.isNotEmpty && schoolCode.isNotEmpty) {
            try {
              final staffRepository = serviceLocator<StaffRepository>();
              // If user is ORGANIZATION_ADMIN for this org, use schoolCode = '-'
              // for the staff-code API as required by backend.
              String effectiveSchoolCode = schoolCode;
              const orgAdminRole = 'ORGANIZATION_ADMIN';
              final rolesForOrg = response.roles
                  .where((r) => r.organizationCode == orgCode)
                  .toList();
              final isOrgAdmin = rolesForOrg
                  .any((r) => r.role.toUpperCase() == orgAdminRole);
              if (isOrgAdmin) {
                effectiveSchoolCode = '-';
              }

              final staffCode = await staffRepository.getStaffCodeForUser(
                userCode: response.userCode,
                organizationCode: orgCode,
                schoolCode: effectiveSchoolCode,
              );
              final trimmed = (staffCode ?? '').trim();
              if (trimmed.isNotEmpty) {
                // Persist resolved staffCode for later screens.
                await _localDataSource.saveStaffCode(
                  userCode: response.userCode,
                  staffCode: trimmed,
                );

                // Prefetch staff profile once at login using the my-profile controller
                // so that UserProfileScreen can render data immediately from cache.
                try {
                  final profile = await staffRepository.getStaffProfile(
                    staffCode: trimmed,
                  );
                  // Save staffType for quick persona display in ProfileMenuHeader.
                  final storage = serviceLocator<StorageService>();
                  await storage.saveString(
                    StorageKeys.staffType,
                    profile.staffType,
                  );
                } catch (_) {
                  // Non-blocking: profile prefetch failure should not affect login flow.
                }
              }
            } catch (_) {
              // Non-blocking: profile screen can still work without staffCode.
            }
          }
        } catch (_) {
        // Do not block login if context or staff/profile APIs fail.
        }

        // Only login + login-context during login flow. No school prefetch.
        emit(
          AuthLoaded(
            loginResponse: response,
            schoolsByOrg: const <String, List<Map<String, String>>>{},
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

  /// Fetches school names for an org using role mapping: ORGANIZATION_ADMIN
  /// → isAdmin true (all schools); SCHOOL_ADMIN → isAdmin false with school
  /// codes from roles.
  Future<void> loadSchoolsForOrg(String organizationCode) async {
    LoginResponseModel? login;
    if (state is AuthLoaded) {
      login = (state as AuthLoaded).loginResponse;
    } else {
      login = await _localDataSource.getCachedLoginResponse();
    }
    if (login == null) return;

    final rolesForOrg = login.roles
        .where((r) => r.organizationCode == organizationCode)
        .toList();
    const orgAdminRole = 'ORGANIZATION_ADMIN';
    final isOrgAdmin = rolesForOrg
        .any((r) => r.role.toUpperCase() == orgAdminRole.toUpperCase());
    final schoolCodes = rolesForOrg
        .map((r) => r.schoolCode)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    final bool isAdmin;
    final List<String> codes;
    if (isOrgAdmin) {
      isAdmin = true;
      codes = [];
    } else {
      isAdmin = false;
      codes = schoolCodes;
    }

    final staticFallback = staticSchoolSelectionEntriesForOrg(
      organizationCode: organizationCode,
      restrictToSchoolCodes: isAdmin ? const <String>[] : codes,
    );

    final prev = state is AuthLoaded ? state as AuthLoaded : null;
    emit(AuthLoaded(
      loginResponse: login,
      schoolsByOrg: prev?.schoolsByOrg ?? const <String, List<Map<String, String>>>{},
      isPrefetchingSchools: true,
      lastErrorMessage: null,
      orgNames: prev?.orgNames ?? const [],
      hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
      redirectUrl: prev?.redirectUrl,
    ));

    try {
      final result = await _remoteDataSource.getSchoolNamesByOrg(
        organizationCode: organizationCode,
        schoolCodes: codes,
        isAdmin: isAdmin,
        accessToken: login.accessToken,
      );
      var schoolList = result.dataWithCodes.isNotEmpty
          ? result.dataWithCodes
          : result.data
              .map((n) => {'schoolCode': n, 'schoolName': n})
              .toList();

      // If API returns empty (or unexpected payload), fallback to static catalog.
      if (schoolList.isEmpty && staticFallback.isNotEmpty) {
        schoolList = staticFallback;
      }
      final updated =
          Map<String, List<Map<String, String>>>.from(prev?.schoolsByOrg ?? {});
      updated[organizationCode] = schoolList;

      // Also update organization display name (orgNames) when API
      // returns organizationName in the payload. This ensures that
      // Select Organization / Select School screens can show a human-
      // readable org name instead of the raw code, even after app
      // restart when only the school-names API was called.
      List<String> nextOrgNames = prev?.orgNames ?? const [];
      final orgNameFromSchools = result.organizationName.trim();
      if (orgNameFromSchools.isNotEmpty) {
        // Derive canonical org-code order from roles (deduped, first occurrence).
        final codesFromRoles = <String>[];
        for (final r in login.roles) {
          final code = r.organizationCode;
          if (code.isNotEmpty && !codesFromRoles.contains(code)) {
            codesFromRoles.add(code);
          }
        }
        if (codesFromRoles.isNotEmpty) {
          // Ensure orgNames list matches length of codes list.
          if (nextOrgNames.length != codesFromRoles.length) {
            // Start from empty list sized to match codes length.
            nextOrgNames = List<String>.filled(codesFromRoles.length, '');
          } else {
            nextOrgNames = List<String>.from(nextOrgNames);
          }
          final idx = codesFromRoles.indexOf(organizationCode);
          if (idx != -1) {
            nextOrgNames[idx] = orgNameFromSchools;
          }
        }
      }

      emit(AuthLoaded(
        loginResponse: login,
        schoolsByOrg: updated,
        isPrefetchingSchools: false,
        lastErrorMessage: null,
        orgNames: nextOrgNames,
        hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
        redirectUrl: prev?.redirectUrl,
      ));
    } catch (e) {
      // Fallback to static catalog when API fails so user can still continue.
      if (staticFallback.isNotEmpty) {
        final updated =
            Map<String, List<Map<String, String>>>.from(prev?.schoolsByOrg ?? {});
        updated[organizationCode] = staticFallback;
        emit(AuthLoaded(
          loginResponse: login,
          schoolsByOrg: updated,
          isPrefetchingSchools: false,
          lastErrorMessage: null,
          orgNames: prev?.orgNames ?? const [],
          hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
          redirectUrl: prev?.redirectUrl,
        ));
      } else {
        emit(AuthLoaded(
          loginResponse: login,
          schoolsByOrg:
              prev?.schoolsByOrg ?? const <String, List<Map<String, String>>>{},
          isPrefetchingSchools: false,
          lastErrorMessage: e.toString(),
          orgNames: prev?.orgNames ?? const [],
          hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
          redirectUrl: prev?.redirectUrl,
        ));
      }
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

  /// Resolves staffCode and prefetches the staff profile for the given
  /// organization/school combination using the my-profile controller.
  ///
  /// This is used when switching organisations/schools so that
  /// `UserProfileScreen` can render immediately from cache without
  /// showing long loading states.
  Future<void> prefetchStaffProfileForOrgAndSchool({
    required String organizationCode,
    required String schoolCode,
  }) async {
    try {
      LoginResponseModel? login;
      if (state is AuthLoaded) {
        login = (state as AuthLoaded).loginResponse;
      } else {
        login = await _localDataSource.getCachedLoginResponse();
      }
      if (login == null) return;

      // If user is ORGANIZATION_ADMIN for this org, use schoolCode = '-'
      // for the staff-code API as required by backend.
      String effectiveSchoolCode = schoolCode;
      const orgAdminRole = 'ORGANIZATION_ADMIN';
      final rolesForOrg = login.roles
          .where((r) => r.organizationCode == organizationCode)
          .toList();
      final isOrgAdmin = rolesForOrg
          .any((r) => r.role.toUpperCase() == orgAdminRole);
      if (isOrgAdmin) {
        effectiveSchoolCode = '-';
      }

      final staffRepository = serviceLocator<StaffRepository>();
      final staffCode = await staffRepository.getStaffCodeForUser(
        userCode: login.userCode,
        organizationCode: organizationCode,
        schoolCode: effectiveSchoolCode,
      );
      final trimmed = (staffCode ?? '').trim();
      if (trimmed.isEmpty) return;

      // Persist resolved staffCode for later screens.
      await _localDataSource.saveStaffCode(
        userCode: login.userCode,
        staffCode: trimmed,
      );

      // Prefetch staff profile once using the my-profile controller so
      // profile screens can render from cache.
      try {
        final profile = await staffRepository.getStaffProfile(
          staffCode: trimmed,
        );
        final storage = serviceLocator<StorageService>();
        await storage.saveString(
          StorageKeys.staffType,
          profile.staffType,
        );
      } catch (_) {
        // Non-blocking
      }
    } catch (_) {
      // Non-blocking: do not fail switch flow on profile prefetch errors.
    }
  }

  /// Fetches organization display names for given org codes.
  /// Updates AuthLoaded.orgNames (same order as [organizationCodes]).
  Future<void> loadOrganizationNames(List<String> organizationCodes) async {
    if (organizationCodes.isEmpty) return;
    LoginResponseModel? login;
    if (state is AuthLoaded) {
      login = (state as AuthLoaded).loginResponse;
    } else {
      login = await _localDataSource.getCachedLoginResponse();
    }
    if (login == null) return;

    final prev = state is AuthLoaded ? state as AuthLoaded : null;
    try {
      final names = await _remoteDataSource.getOrganizationNames(
        organizationCodes: organizationCodes,
        accessToken: login.accessToken,
      );
      emit(AuthLoaded(
        loginResponse: login,
        schoolsByOrg: prev?.schoolsByOrg ?? const {},
        isPrefetchingSchools: prev?.isPrefetchingSchools ?? false,
        lastErrorMessage: prev?.lastErrorMessage,
        orgNames: names,
        hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
        redirectUrl: prev?.redirectUrl,
      ));
    } catch (_) {
      // Non-fatal: keep previous state, org names will fall back to codes
    }
  }
}
