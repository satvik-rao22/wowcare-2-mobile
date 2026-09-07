import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/domain/features/auth/usecases/login_usecase.dart';
import 'package:wowcare/domain/features/notifications/usecases/register_device_fcm_token_usecase.dart';
import 'package:wowcare/domain/features/notifications/usecases/unregister_device_fcm_token_usecase.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/data/static/static_school_catalog.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/core/auth/secure_credential_store.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/firebase/firebase_auth_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/user_details_school_roles.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/core/util/server_time_service.dart';

part 'auth_state.dart';

/// What the sign-in form should prefill: a saved username, whether
/// "remember me" was on, and (only when a biometric reveal succeeded) the
/// saved password.
class SavedCredentialsPrefill extends Equatable {
  const SavedCredentialsPrefill({
    required this.username,
    required this.rememberMe,
    this.password,
  });

  final String username;
  final bool rememberMe;
  final String? password;

  @override
  List<Object?> get props => [username, rememberMe, password];
}

class _BiometricPrefillResult {
  const _BiometricPrefillResult({required this.username, required this.password});

  final String username;
  final String password;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
    required RegisterDeviceFcmTokenUseCase registerDeviceFcmToken,
    required UnregisterDeviceFcmTokenUseCase unregisterDeviceFcmToken,
    required FirebaseAuthService firebaseAuthService,
    required StorageService storageService,
    required StaffRepository staffRepository,
    required KioskAccessControl kioskAccessControl,
    required SecureCredentialStore secureCredentialStore,
  }) : _loginUseCase = loginUseCase,
       _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _registerDeviceFcmToken = registerDeviceFcmToken,
       _unregisterDeviceFcmToken = unregisterDeviceFcmToken,
       _firebaseAuthService = firebaseAuthService,
       _storageService = storageService,
       _staffRepository = staffRepository,
       _kioskAccessControl = kioskAccessControl,
       _secureCredentialStore = secureCredentialStore,
       super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final RegisterDeviceFcmTokenUseCase _registerDeviceFcmToken;
  final UnregisterDeviceFcmTokenUseCase _unregisterDeviceFcmToken;
  final FirebaseAuthService _firebaseAuthService;
  final StorageService _storageService;
  final StaffRepository _staffRepository;
  final KioskAccessControl _kioskAccessControl;
  final SecureCredentialStore _secureCredentialStore;

  bool _offeredBiometricPrefill = false;

  /// What the sign-in form should prefill itself with, resolved from saved
  /// credentials + (if "remember me" was on) a biometric-gated password
  /// reveal. The view only ever calls this — it never talks to
  /// [AuthLocalDataSource]/[StorageService]/[SecureCredentialStore] itself.
  Future<SavedCredentialsPrefill> loadSavedCredentials() async {
    final credentials = await _localDataSource.getSavedCredentials();
    final rememberMeValue =
        await _storageService.getBool(StorageKeys.rememberMe) ?? false;
    var username = credentials['username'] ?? '';
    AppLogger.d(
      '[RememberMe] load: rememberMe=$rememberMeValue savedUser="$username"',
    );

    // "Remember me" password pre-fill: the password lives only in the secure
    // store. If the device has a biometric / passcode we prompt for it first;
    // if it has neither, the password is filled in without a prompt so
    // "Remember me" still works on unsecured devices.
    String? password;
    if (rememberMeValue) {
      final biometric = await _offerBiometricPrefill();
      if (biometric != null) {
        if (biometric.username.isNotEmpty) username = biometric.username;
        password = biometric.password;
      }
    }

    return SavedCredentialsPrefill(
      username: username,
      rememberMe: rememberMeValue,
      password: password,
    );
  }

  Future<_BiometricPrefillResult?> _offerBiometricPrefill() async {
    if (_offeredBiometricPrefill) return null;
    _offeredBiometricPrefill = true;
    try {
      final has = await _secureCredentialStore.hasSavedPassword();
      AppLogger.d('[RememberMe] prefill: hasSavedPassword=$has');
      if (!has) {
        AppLogger.d(
          '[RememberMe] prefill ABORTED — no password in Keychain. It was '
          'either never saved, or wiped (see freshInstallCheck above).',
        );
        return null;
      }
      final creds = await _secureCredentialStore.revealWithBiometrics(
        reason: 'Unlock your saved password to sign in',
      );
      AppLogger.d(
        '[RememberMe] prefill: revealed=${creds != null} '
        'pwLen=${creds?['password']?.length ?? 0}',
      );
      if (creds == null) return null;
      return _BiometricPrefillResult(
        username: creds['username'] ?? '',
        password: creds['password'] ?? '',
      );
    } catch (e) {
      AppLogger.d('[SignIn] biometric prefill error: $e');
      // Biometric cancelled/unavailable — user just types the password.
      return null;
    }
  }

  /// Persists sign-in credentials: username + "remember me" flag go to
  /// normal storage; the password goes ONLY into the biometric-gated secure
  /// store, and only while "remember me" is on (unchecking it wipes the
  /// saved password immediately).
  Future<void> saveCredentials({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final trimmedPassword = password.trim();
    AppLogger.d(
      '[SignIn] saveCredentials rememberMe=$rememberMe '
      'user="$normalizedUsername" pwLen=${trimmedPassword.length}',
    );
    await _localDataSource.saveCredentials(
      normalizedUsername,
      trimmedPassword,
      rememberMe,
    );

    if (rememberMe) {
      await _secureCredentialStore.save(
        username: normalizedUsername,
        password: trimmedPassword,
      );
    } else {
      await _secureCredentialStore.clear();
    }
  }

  /// The organisation code saved when the last login-context response came
  /// back with a null schoolCode (used to route straight into school
  /// selection instead of org selection on a later sign-in).
  Future<String?> getSavedOrganizationCode() {
    return _storageService.getString(StorageKeys.organizationCode);
  }

  /// Mark login as completed only after org + school selection is done.
  /// FCM registration is non-blocking and errors don't interrupt login completion.
  Future<void> completeLogin({
    required String selectedOrgCode,
    required String selectedSchoolName,
    String? selectedSchoolCode,
  }) async {
    LoginResponseModel? loginResponse;
    if (state is AuthLoaded) {
      final loaded = state as AuthLoaded;
      loginResponse = loaded.loginResponse;
      await _localDataSource.cacheLoginResponse(loginResponse);
    }
    await _localDataSource.saveOrgAndSchoolSelection(
      orgCode: selectedOrgCode,
      schoolName: selectedSchoolName,
      schoolCode: selectedSchoolCode,
    );

    // Sign Flutter into Firebase Auth using a custom token from the backend.
    // Required for Firestore realtime listeners (inbox + message threads).
    // Non-fatal: failures only affect realtime; REST APIs continue to work.
    try {
      AppLogger.d('[AUTH] completeLogin — signing into Firebase');
      _firebaseAuthService.signIn();
    } catch (e) {
      AppLogger.w(
        '[AUTH] Firebase sign-in failed during completeLogin (non-fatal): $e',
      );
    }

    // FCM registration is non-blocking when login is completed
    try {
      AppLogger.d('[AUTH] Login completed — registering FCM token');
      await _registerDeviceFcmTokenIfSessionReady();
    } catch (e) {
      // Non-fatal: FCM failures should not block login completion
      AppLogger.w(
        '[AUTH] FCM registration failed during completeLogin (non-fatal): $e',
      );
    }
  }

  Future<void> _registerDeviceFcmTokenIfSessionReady() async {
    try {
      final loginCompleted =
          await _storageService.getBool(
            StorageKeys.loginCompleted,
          ) ??
          false;
      if (!loginCompleted) {
        AppLogger.d(
          '[AUTH-FCM] Session not ready (loginCompleted=false) — skipping registration',
        );
        return;
      }

      AppLogger.d('[AUTH-FCM] Session ready — registering FCM token');
      // Session just became ready (fresh login or restore) — align "now" with
      // the server clock now that a token is available, since there's no
      // app-resume event on a cold login. Fire-and-forget; device time otherwise.
      unawaited(ServerTimeService.instance.sync());
      await _registerDeviceFcmToken();
    } catch (e) {
      // Non-fatal: FCM registration errors should not interrupt auth flow
      AppLogger.w(
        '[AUTH-FCM] FCM registration encountered error (non-fatal): $e',
      );
    }
  }

  /// Set selected org/school (e.g. when switching organisation from Dashboard).
  /// FCM registration is non-blocking and errors are logged but don't interrupt the flow.
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

    // Re-sign in to Firebase with the new school context so Firestore
    // listeners (inbox + message threads) immediately use the correct
    // org/school path. Mirrors the web's AppTopbar useEffect which calls
    // signInToFirebase() whenever the school code changes.
    // Non-fatal: Firestore listeners retry on permission-denied with backoff.
    try {
      String? accessToken;
      if (state is AuthLoaded) {
        accessToken = (state as AuthLoaded).loginResponse.accessToken;
      } else {
        final cached = await _localDataSource.getCachedLoginResponse();
        accessToken = cached?.accessToken;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        AppLogger.d('[AUTH] Org/school changed — re-signing into Firebase');
        _firebaseAuthService.signIn();
      }
    } catch (e) {
      AppLogger.w(
        '[AUTH] Firebase re-sign-in on school change failed (non-fatal): $e',
      );
    }

    // FCM registration is non-blocking when org/school changes
    try {
      AppLogger.d('[AUTH] Org/school changed — re-registering FCM token');
      await _registerDeviceFcmToken();
    } catch (e) {
      // Non-fatal: FCM failures should not block org/school selection
      AppLogger.w('[AUTH] FCM re-registration failed (non-fatal): $e');
    }
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
        // Restore Firebase Auth session so Firestore listeners work without
        // requiring the user to log in again. AuthInterceptor on the shared
        // Dio instance provides the current token and org/school codes.
        try {
          AppLogger.d(
            '[AUTH] App initialized — restoring Firebase Auth session',
          );
          _firebaseAuthService.signIn();
        } catch (e) {
          AppLogger.w(
            '[AUTH] Firebase sign-in during init failed (non-fatal): $e',
          );
        }

        // FCM init may have run before splash restored org/school — register now (non-blocking).
        try {
          AppLogger.d(
            '[AUTH] App initialized with cached session — registering FCM token',
          );
          await _registerDeviceFcmTokenIfSessionReady();
        } catch (e) {
          // Non-fatal: FCM failures should not prevent app initialization
          AppLogger.w(
            '[AUTH] FCM registration during init failed (non-fatal): $e',
          );
        }
      } else {
        emit(const AuthInitial());
      }
    } catch (e) {
      // Silently fall back to initial state if anything goes wrong.
      AppLogger.w(
        '[AUTH] Initialize failed, falling back to initial state: $e',
      );
      emit(const AuthInitial());
    }
  }

  /// Verifies (via `/api/v1/users/details`, the backend's source of truth for
  /// school approval status) that at least one school tied to this login's
  /// roles is ACTIVE. Returns null when login may proceed; otherwise returns
  /// the message to surface to the user.
  ///
  /// Roles with no schoolCode (e.g. org-level admins) are not school-scoped
  /// and are skipped. A verification failure (network error, etc.) never
  /// blocks login — it's treated the same as an unknown/missing status.
  Future<String?> _pendingSchoolBlockMessage(
    LoginResponseModel response,
  ) async {
    final schoolRoles = response.roles
        .where(
          (r) =>
              r.organizationCode.trim().isNotEmpty &&
              r.schoolCode.trim().isNotEmpty,
        )
        .toList();
    if (schoolRoles.isEmpty) return null;

    List<Map<String, dynamic>> userDetails;
    try {
      userDetails = await _remoteDataSource.getUserDetails(
        accessToken: response.accessToken,
      );
    } catch (e) {
      AppLogger.w(
        '[AUTH] School status verification failed (non-fatal): $e',
      );
      return null;
    }

    final relevantStatuses = schoolRoles
        .map(
          (r) => schoolStatusFromUserDetails(
            userDetails,
            r.organizationCode,
            r.schoolCode,
          ),
        )
        .where((s) => s != null)
        .cast<String>()
        .toList();

    // Only block when EVERY school tied to this login is explicitly
    // non-active. An unknown/missing status is treated as active so a
    // backend hiccup or unmapped school never locks a legitimate user out.
    if (relevantStatuses.isNotEmpty &&
        relevantStatuses.every((s) => s != 'ACTIVE')) {
      if (relevantStatuses.contains('PENDING')) {
        return 'Your school account is pending approval. Please contact your administrator.';
      }
      return 'Your school account is not active. Please contact your administrator.';
    }
    return null;
  }

  /// Verifies from the backend (`/api/v1/users/details`, live — not the
  /// cached snapshot) that [schoolCode] under [organizationCode] is ACTIVE
  /// before a school switch (drawer dropdown, org-switch flow, or a
  /// notification-driven switch) is allowed to proceed. Returns the message
  /// to surface and block on, or null when the switch may proceed.
  ///
  /// Fails open: a verification error (network, missing token, etc.) never
  /// blocks the switch, matching the login-time check's policy.
  Future<String?> verifySchoolActiveOrBlockMessage({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final org = organizationCode.trim();
    final school = schoolCode.trim();
    if (org.isEmpty || school.isEmpty) return null;

    final accessToken = await TokenRefreshService.instance.readAccessToken();
    if (accessToken.isEmpty) return null;

    List<Map<String, dynamic>> userDetails;
    try {
      userDetails = await _remoteDataSource.getUserDetails(
        accessToken: accessToken,
      );
    } catch (e) {
      AppLogger.w(
        '[AUTH] School status verification failed (non-fatal): $e',
      );
      return null;
    }

    final status = schoolStatusFromUserDetails(userDetails, org, school);
    if (status == null || status == 'ACTIVE') return null;
    if (status == 'PENDING') {
      return 'This school is pending approval. Please contact your administrator.';
    }
    return 'This school is not active. Please contact your administrator.';
  }

  /// Live (not cached) backend status per schoolCode for [organizationCode],
  /// straight from `/api/v1/users/details`. Used to hide non-ACTIVE (e.g.
  /// PENDING) schools from the org/school selection pickers during login —
  /// at that point in the flow the `/users/details` cache RoleCubit
  /// populates post-login may not exist yet, so the cached snapshot alone
  /// isn't reliable here.
  ///
  /// Returns an empty map (fail open — nothing gets hidden) on any
  /// verification error, so a backend hiccup never blocks org/school
  /// selection outright.
  Future<Map<String, String>> fetchSchoolStatusesForOrg(
    String organizationCode,
  ) async {
    final org = organizationCode.trim();
    if (org.isEmpty) return const <String, String>{};

    final accessToken = await TokenRefreshService.instance.readAccessToken();
    if (accessToken.isEmpty) return const <String, String>{};

    List<Map<String, dynamic>> userDetails;
    try {
      userDetails = await _remoteDataSource.getUserDetails(
        accessToken: accessToken,
      );
    } catch (e) {
      AppLogger.w('[AUTH] Fetching school statuses failed (non-fatal): $e');
      return const <String, String>{};
    }

    final statuses = <String, String>{};
    for (final user in userDetails) {
      final uOrg = (user['organizationCode'] ?? '').toString().trim();
      if (uOrg != org) continue;
      final schools = user['schools'];
      if (schools is! List) continue;
      for (final s in schools) {
        if (s is! Map) continue;
        final code = (s['schoolCode'] ?? '').toString().trim();
        if (code.isEmpty) continue;
        final status = (s['status'] ?? '').toString().trim().toUpperCase();
        if (status.isNotEmpty) statuses[code] = status;
      }
    }
    return statuses;
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
        // A failed login likely means the saved password is now wrong —
        // wipe it so we never pre-fill stale/incorrect credentials.
        _secureCredentialStore.clear();
        emit(AuthError(message));
      },
      (response) async {
        // SUPERADMIN SHORT-CIRCUIT: this role is web-portal only. Block before
        // anything is cached or persisted so no mobile session is established.
        if (loginResponseIsSuperAdmin(response.roles)) {
          emit(
            const AuthError(
              'Super Admin accounts can only be accessed through the web portal.',
            ),
          );
          return;
        }

        // SCHOOL STATUS CHECK: block before anything is cached or persisted
        // when every school tied to this login is not yet ACTIVE (e.g. still
        // PENDING approval), so no mobile session is established.
        final blockMessage = await _pendingSchoolBlockMessage(response);
        if (blockMessage != null) {
          emit(AuthError(blockMessage));
          return;
        }

        // KIOSK SHORT-CIRCUIT: check role BEFORE any further processing.
        // This prevents all unnecessary APIs (context, staff lookup, profile, PIN) for kiosk users.
        if (loginResponseIsKioskUser(response.roles)) {
          // Persist login response for kiosk users (needed for cold-start session restore)
          try {
            await _localDataSource.cacheLoginResponse(response);
          } catch (_) {
            // Non-fatal: if caching fails, login can still proceed.
          }

          // Extract and store schoolCode from kiosk user's role for QR API
          try {
            final kioskRole = response.roles.firstWhere(
              (r) => r.role.contains('KIOSK'),
            );
            final schoolCode = kioskRole.schoolCode.trim();
            final orgCode = kioskRole.organizationCode.trim();
            if (schoolCode.isNotEmpty && orgCode.isNotEmpty) {
              // Fetch proper school name and org name from /api/v1/users/details
              String schoolName = schoolCode; // fallback to code
              String orgName = orgCode; // fallback to code
              String roleFromApi = 'KIOSK'; // fallback role
              int permissionCount = 0;

              try {
                AppLogger.d(
                  '[Kiosk] Fetching user details from /api/v1/users/details with token',
                );

                // Call the API directly
                final userDetailsList = await _remoteDataSource.getUserDetails(
                  accessToken: response.accessToken,
                );

                if (userDetailsList.isNotEmpty) {
                  final userDetailData = userDetailsList.first;

                  // Extract organization name
                  if (userDetailData['organizationName'] != null) {
                    final extractedOrgName =
                        (userDetailData['organizationName'] as String?)
                            ?.trim() ??
                        '';
                    if (extractedOrgName.isNotEmpty) {
                      orgName = extractedOrgName;
                    }
                  }

                  // Find matching school in user's schools list
                  final schools =
                      userDetailData['schools'] as List<dynamic>? ?? [];
                  for (final schoolData in schools) {
                    if (schoolData is Map<String, dynamic>) {
                      final code =
                          (schoolData['schoolCode'] as String?)?.trim() ?? '';
                      if (code == schoolCode) {
                        // Extract school name
                        final name =
                            (schoolData['schoolName'] as String?)?.trim() ?? '';
                        if (name.isNotEmpty) {
                          schoolName = name;
                        }

                        // Extract role
                        final role =
                            (schoolData['role'] as String?)?.trim() ?? '';
                        if (role.isNotEmpty) {
                          roleFromApi = role.toUpperCase();
                        }

                        // Extract permissions
                        final perms =
                            schoolData['permissions'] as List<dynamic>? ?? [];
                        permissionCount = perms.length;

                        break;
                      }
                    }
                  }

                  AppLogger.d(
                    '[Kiosk] Fetched user details: '
                    'schoolName=$schoolName, '
                    'schoolCode=$schoolCode, '
                    'organizationName=$orgName, '
                    'role=$roleFromApi, '
                    'permissions=$permissionCount',
                  );
                }
              } catch (e) {
                AppLogger.w(
                  '[Kiosk] Error fetching user details: $e. Using fallback values.',
                );
              }

              // Store proper school name and org name
              await _localDataSource.setSelectedOrgAndSchool(
                organizationCode: orgCode,
                schoolCode: schoolCode,
                schoolName: schoolName,
              );

              AppLogger.d(
                '[AUTH] Kiosk login: org=$orgCode (name=$orgName), '
                'school=$schoolCode (name=$schoolName), role=$roleFromApi',
              );
            }
          } catch (e) {
            AppLogger.w('[AUTH] Error processing kiosk login: $e');
            // Non-fatal: if storing fails, kiosk dashboard will handle missing schoolCode
          }

          // Emit immediately and return — skip all post-login processing
          emit(
            AuthLoaded(
              loginResponse: response,
              schoolsByOrg: const <String, List<Map<String, String>>>{},
              isPrefetchingSchools: false,
              lastErrorMessage: null,
              orgNames: const [],
              hasLastSchoolFromContext: false,
              redirectUrl: null,
            ),
          );
          return; // skip context API, staff lookup, staff profile, PIN
        }

        // Non-kiosk users: clear any stale kiosk state IMMEDIATELY.
        // A previous kiosk session may have left kiosk_mode_active=true in
        // storage. Clear both storage and static cache before any navigation
        // so the router never sees a stale kiosk flag for this user.
        try {
          final kioskAccess = _kioskAccessControl;
          await kioskAccess.deactivateKioskMode();
          AppLogger.d(
            '[AUTH ROLE CHECK] Non-kiosk login — kiosk state cleared. '
            'Role(s): ${response.roles.map((r) => r.role).join(', ')}. '
            'IsKiosk: false.',
          );
        } catch (_) {
          // Fallback: force static cache clear even if DI lookup fails.
          KioskAccessControl.clearCacheForNonKioskLogin();
        }

        // Persist latest login response (tokens, user, roles) for future app launches.
        try {
          await _localDataSource.cacheLoginResponse(response);
        } catch (_) {
          // Non-fatal: if caching fails, login can still proceed.
        }

        // If the user is associated with exactly 1 organization AND 1 school,
        // auto-select them from the login response and persist to local storage.
        // This ensures every screen can rely on StorageKeys.schoolCode (no guessing from roles).
        try {
          final orgCodes = response.roles
              .map((r) => r.organizationCode.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          final schoolCodes = response.roles
              .map((r) => r.schoolCode.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();

          if (orgCodes.length == 1 && schoolCodes.length == 1) {
            await _localDataSource.setSelectedOrgAndSchool(
              organizationCode: orgCodes.first,
              schoolCode: schoolCodes.first,
              schoolName: schoolCodes.first,
            );
          }
        } catch (_) {
          // Non-blocking
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
          hasLastSchoolFromContext = await _localDataSource
              .saveOrgAndSchoolFromContext(contextData);

          // Raw values from login-context (may be null/empty, especially LastLoginSchoolCode).
          final String contextOrgCode =
              (contextData['LastLoginOrganizationCode'] as String?)?.trim() ??
              '';
          final String contextSchoolCode =
              (contextData['LastLoginSchoolCode'] as String?)?.trim() ?? '';

          // When orgCode or schoolCode is null (or both), use redirectUrl to decide where to open.
          if (contextOrgCode.isEmpty || contextSchoolCode.isEmpty) {
            final rawRedirect = contextData['redirectUrl'];
            redirectUrl = rawRedirect is String ? rawRedirect.trim() : null;
            // IMPORTANT: do NOT overwrite non-empty schoolCode from login with an empty value.
            // If org is present, ensure at least organizationCode is in storage; keep existing school.
            if (contextOrgCode.isNotEmpty) {
              final storage = _storageService;
              final existingSchool =
                  (await storage.getString(StorageKeys.schoolCode) ?? '')
                      .trim();
              if (existingSchool.isNotEmpty) {
                await _localDataSource.setSelectedOrgAndSchool(
                  organizationCode: contextOrgCode,
                  schoolCode: existingSchool,
                  schoolName: existingSchool,
                );
              } else {
                // Fall back to contextSchoolCode only when it's non-empty.
                if (contextSchoolCode.isNotEmpty) {
                  await _localDataSource.setSelectedOrgAndSchool(
                    organizationCode: contextOrgCode,
                    schoolCode: contextSchoolCode,
                    schoolName: contextSchoolCode,
                  );
                }
              }
            }
          }

          // After login-context, resolve staffCode and prefetch staff profile + PIN.
          try {
            final storage = _storageService;
            var orgCode = contextOrgCode;
            if (orgCode.isEmpty) {
              orgCode = response.roles
                  .map((r) => r.organizationCode.trim())
                  .firstWhere((c) => c.isNotEmpty, orElse: () => '');
            }
            if (orgCode.isEmpty) {
              orgCode =
                  (await storage.getString(StorageKeys.organizationCode) ?? '')
                      .trim();
            }

            var schoolCode = contextSchoolCode;
            if (schoolCode.isEmpty) {
              schoolCode =
                  (await storage.getString(StorageKeys.schoolCode) ?? '')
                      .trim();
            }

            const orgAdminRole = 'ORGANIZATION_ADMIN';
            final isOrgAdminForSelectedOrg = response.roles.any(
              (r) =>
                  r.organizationCode.trim() == orgCode &&
                  r.role.toUpperCase() == orgAdminRole,
            );
            // Staff-code lookup uses '-' for org admins (org-level lookup).
            // The persisted selected school must remain the real LastLoginSchoolCode.
            final staffLookupSchoolCode = isOrgAdminForSelectedOrg
                ? '-'
                : schoolCode;

            final rolesJson = jsonEncode(
              response.roles.map((e) => e.toJson()).toList(),
            );
            final skipStaffLookup = shouldSkipStaffCodeResolutionForContext(
              rolesJson: rolesJson,
              organizationCode: orgCode,
              schoolCode: staffLookupSchoolCode,
            );

            if (skipStaffLookup) {
              await storage.remove(StorageKeys.staffCode);
              await storage.remove(StorageKeys.staffCodeUser);
              await storage.remove(StorageKeys.staffCodeOrganization);
              await storage.remove(StorageKeys.staffCodeSchool);
            } else if (orgCode.isNotEmpty && staffLookupSchoolCode.isNotEmpty) {
              final staffRepository = _staffRepository;
              String trimmed = '';
              try {
                final staffCode = await staffRepository.getStaffCodeForUser(
                  userCode: response.userCode,
                  organizationCode: orgCode,
                  schoolCode: staffLookupSchoolCode,
                );
                trimmed = (staffCode ?? '').trim();
              } catch (_) {
                // 403/404 — no staff record for this user, or the gateway
                // rejects the staff-code bootstrap. Treat as "not staff".
                trimmed = '';
              }
              if (trimmed.isEmpty) {
                // The admin/staff bootstrap produced no staffCode. If this user
                // is ALSO a guardian for this org/school, switch the active
                // persona to guardian so the session works (the guardian path
                // never sends x-staff-code) instead of dying on every call.
                await _maybeFallbackToGuardianPersona(
                  storage: storage,
                  roles: response.roles,
                  organizationCode: orgCode,
                  schoolCode: schoolCode,
                );
              }
              if (trimmed.isNotEmpty) {
                if (schoolCode.isNotEmpty) {
                  await _localDataSource.setSelectedOrgAndSchool(
                    organizationCode: orgCode,
                    schoolCode: schoolCode,
                    schoolName: schoolCode,
                  );
                }
                await _localDataSource.saveStaffCode(
                  userCode: response.userCode,
                  staffCode: trimmed,
                );

                try {
                  final profile = await staffRepository.getStaffProfile(
                    staffCode: trimmed,
                    forEditStaff: true,
                  );
                  await storage.saveString(
                    StorageKeys.staffType,
                    profile.staffType,
                  );
                  await storage.saveString(
                    StorageKeys.staffAllowedClassroomCodes,
                    jsonEncode(profile.allowedClassroomCodes),
                  );
                } catch (_) {}

                try {
                  final pin = await staffRepository.getStaffSignInPin(
                    staffCode: trimmed,
                  );
                  if (pin.trim().isNotEmpty) {
                    await storage.saveString(StorageKeys.staffPin, pin.trim());
                  }
                } catch (_) {}
              }
            }
          } catch (_) {
            // Non-blocking: profile screen can still work without staffCode.
          }
        } catch (_) {
          // Do not block login if context or staff/profile APIs fail.
        }

        // Safety net: a user who belongs to exactly one organization but
        // MULTIPLE schools under it never hits the single-org/single-school
        // auto-select above, and a first-ever login-context response returns
        // null for both LastLoginOrganizationCode and LastLoginSchoolCode. If
        // the backend's redirectUrl still says "dashboard" in that case (see
        // the dashboard branch in sign_in_screen.dart), the app navigates
        // straight in with NO organizationCode ever persisted. Every
        // subsequent API call then 400s with "Missing required header:
        // X-Organization-Code" (including the Firebase token exchange, whose
        // failure cascades into permission-denied Firestore listeners), and
        // `loginCompleted` — which setSelectedOrgAndSchool only flips once
        // BOTH org and school are non-empty — stays false, so FCM
        // registration is skipped too. Default to the single org + its first
        // available school so the session always ends up usable.
        try {
          final storage = _storageService;
          final storedOrgCode =
              (await storage.getString(StorageKeys.organizationCode) ?? '')
                  .trim();
          if (storedOrgCode.isEmpty) {
            final orgCodes = response.roles
                .map((r) => r.organizationCode.trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();
            if (orgCodes.length == 1) {
              final fallbackSchoolCode = response.roles
                  .where((r) => r.organizationCode.trim() == orgCodes.first)
                  .map((r) => r.schoolCode.trim())
                  .firstWhere((c) => c.isNotEmpty, orElse: () => '');
              if (fallbackSchoolCode.isNotEmpty) {
                await _localDataSource.setSelectedOrgAndSchool(
                  organizationCode: orgCodes.first,
                  schoolCode: fallbackSchoolCode,
                  schoolName: fallbackSchoolCode,
                );
              }
            }
          }
        } catch (_) {
          // Non-blocking
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

        // Sign into Firebase Auth for Firestore realtime (live sync). This login
        // path auto-resolves org/school from the login-context and navigates
        // straight in WITHOUT going through the school-selection screen (which is
        // the only place that called completeLogin/setSelectedOrgAndSchool → signIn).
        // Without this, an auto-navigated login (e.g. org-admin with a last-login
        // school) never authenticates to Firestore, so message/inbox live sync stays
        // dead (silent permission-denied) until a re-login. Session + org/school are
        // persisted above, so the AuthInterceptor injects the right token + headers.
        // Non-fatal: failures only affect realtime; REST APIs keep working.
        try {
          AppLogger.d('[AUTH] Login flow complete — signing into Firebase');
          _firebaseAuthService.signIn();
        } catch (e) {
          AppLogger.w(
            '[AUTH] Firebase sign-in after login failed (non-fatal): $e',
          );
        }

        // Prefetch parent/guardian children upfront so UI doesn't trigger the
        // guardian/children APIs on first open of dropdown/profile screens.
        try {
          final hasGuardian = response.roles.any(
            (r) => roleStringIsGuardianPersona(r.role),
          );
          if (hasGuardian) {
            final navCtx = CoreUtils.rootNavigatorKey.currentContext;
            if (navCtx != null && navCtx.mounted) {
              navCtx.read<ParentChildCubit>().invalidate();
              await navCtx.read<ParentChildCubit>().ensureLoaded(force: true);
            }
          }
        } catch (_) {
          // Non-blocking
        }

        // FCM init runs at app start (before login) — register once session exists.
        // Non-blocking: FCM registration failures must NOT break the login flow.
        try {
          await _registerDeviceFcmTokenIfSessionReady();
        } catch (e) {
          AppLogger.w(
            '[AUTH] FCM registration failed after login (non-fatal): $e',
          );
        }
      },
    );
  }

  /// When the admin/staff bootstrap can't resolve a staffCode but the user is
  /// also a guardian for [organizationCode]/[schoolCode], switch the active
  /// persona to that guardian role so the session works (guardian calls never
  /// send `x-staff-code`). Only sets [StorageKeys.activeSchoolRole] — it does
  /// NOT rewrite the roles list, so the admin persona stays available for the
  /// manual switcher.
  Future<void> _maybeFallbackToGuardianPersona({
    required StorageService storage,
    required List<RoleModel> roles,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final org = organizationCode.trim();
    final school = schoolCode.trim();
    if (org.isEmpty) return;

    bool matchesContext(RoleModel r) {
      if (r.organizationCode.trim() != org) return false;
      final rSchool = r.schoolCode.trim();
      // School-scoped roles must match; org-wide ('' or '-') always apply.
      return school.isEmpty ||
          rSchool.isEmpty ||
          rSchool == '-' ||
          rSchool == school;
    }

    final contextRoles = roles.where(matchesContext).toList();
    if (contextRoles.isEmpty) return;

    RoleModel? guardianRole;
    var hasNonGuardian = false;
    for (final r in contextRoles) {
      if (roleStringIsGuardianPersona(r.role)) {
        guardianRole ??= r;
      } else {
        hasNonGuardian = true;
      }
    }
    // Only fall back for genuine dual-role accounts (admin/staff AND guardian).
    if (guardianRole == null || !hasNonGuardian) return;

    await storage.saveString(
      StorageKeys.activeSchoolRole,
      guardianRole.role.trim(),
    );
    AppLogger.d(
      '[AUTH] Staff bootstrap failed for a dual-role user — '
      'falling back to guardian persona (${guardianRole.role}).',
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
    final isOrgAdmin = rolesForOrg.any(
      (r) => r.role.toUpperCase() == orgAdminRole.toUpperCase(),
    );
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
    ).cast<Map<String, String>>();

    final prev = state is AuthLoaded ? state as AuthLoaded : null;
    emit(
      AuthLoaded(
        loginResponse: login,
        schoolsByOrg:
            prev?.schoolsByOrg ?? const <String, List<Map<String, String>>>{},
        isPrefetchingSchools: true,
        lastErrorMessage: null,
        orgNames: prev?.orgNames ?? const [],
        hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
        redirectUrl: prev?.redirectUrl,
      ),
    );

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
                .map((n) => {'schoolCode': n, 'schoolName': ''})
                .toList();

      // If API returns empty (or unexpected payload), fallback to static catalog.
      if (schoolList.isEmpty && staticFallback.isNotEmpty) {
        schoolList = staticFallback;
      }
      final updated = Map<String, List<Map<String, String>>>.from(
        prev?.schoolsByOrg ?? {},
      );
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

      emit(
        AuthLoaded(
          loginResponse: login,
          schoolsByOrg: updated,
          isPrefetchingSchools: false,
          lastErrorMessage: null,
          orgNames: nextOrgNames,
          hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
          redirectUrl: prev?.redirectUrl,
        ),
      );

      // Persist fetched school names into the local organizations+schools
      // cache so helpers (SchoolContextHelper) can resolve display names
      // even after app restart. Merge into existing list while updating
      // names for matching org+school entries.
      try {
        final existing = await _localDataSource.getOrganizationsAndSchools();
        final merged = List<Map<String, String>>.from(existing);
        for (final e in schoolList) {
          final code = (e['schoolCode'] ?? '').toString().trim();
          final name = (e['schoolName'] ?? '').toString().trim();
          if (code.isEmpty) continue;
          final entry = <String, String>{
            'organizationCode': organizationCode,
            'schoolCode': code,
            'schoolName': name,
          };
          final idx = merged.indexWhere(
            (m) =>
                (m['organizationCode'] ?? '') == organizationCode &&
                (m['schoolCode'] ?? '') == code,
          );
          if (idx != -1) {
            final existingName = (merged[idx]['schoolName'] ?? '')
                .toString()
                .trim();
            // Avoid overwriting an existing pretty name with an empty value
            // or with a code. Only replace when the new name is non-empty
            // and appears more informative.
            if (name.isNotEmpty && name != code) {
              merged[idx] = entry;
            } else if (existingName.isEmpty) {
              // existing had no name, accept whatever we have (even code)
              merged[idx] = entry;
            }
          } else {
            merged.insert(0, entry);
          }
        }
        await _localDataSource.saveOrganizationsAndSchools(merged);
      } catch (e) {
        AppLogger.d('[AUTH] failed to persist organizationsAndSchools: $e');
      }
    } catch (e) {
      // Fallback to static catalog when API fails so user can still continue.
      if (staticFallback.isNotEmpty) {
        final updated = Map<String, List<Map<String, String>>>.from(
          prev?.schoolsByOrg ?? {},
        );
        updated[organizationCode] = staticFallback;
        emit(
          AuthLoaded(
            loginResponse: login,
            schoolsByOrg: updated,
            isPrefetchingSchools: false,
            lastErrorMessage: null,
            orgNames: prev?.orgNames ?? const [],
            hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
            redirectUrl: prev?.redirectUrl,
          ),
        );
      } else {
        emit(
          AuthLoaded(
            loginResponse: login,
            schoolsByOrg:
                prev?.schoolsByOrg ??
                const <String, List<Map<String, String>>>{},
            isPrefetchingSchools: false,
            lastErrorMessage: ApiErrorHandler.extractErrorMessage(e),
            orgNames: prev?.orgNames ?? const [],
            hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
            redirectUrl: prev?.redirectUrl,
          ),
        );
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
      await _unregisterDeviceFcmToken();
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
    }

    // Sign out of Firebase so Firestore listeners lose read permission
    // immediately. Non-fatal: logout must succeed even if Firebase sign-out fails.
    try {
      await _firebaseAuthService.signOut();
    } catch (e) {
      AppLogger.w('[AUTH] Firebase sign-out failed (non-fatal): $e');
    }

    // NOTE: clearCache() now preserves the "Remember me" username + flag so the
    // sign-in form can pre-fill after logout. The password itself stays in the
    // biometric-gated secure store. We intentionally do NOT call
    // clearCredentials() here — that would defeat the pre-fill requirement.
    await _localDataSource.clearCache();
    final navCtx = CoreUtils.rootNavigatorKey.currentContext;
    if (navCtx != null && navCtx.mounted) {
      try {
        // resetForLogout, not invalidate: logout must also erase the
        // PERSISTED child selection so the next account to sign in on this
        // device inherits nothing from this one.
        unawaited(navCtx.read<ParentChildCubit>().resetForLogout());
      } catch (_) {}
      try {
        navCtx.read<RoleCubit>().resetSessionForLogout();
      } catch (_) {}
    }
    emit(const AuthInitial());
  }

  Future<void> clearCache() async {
    try {
      await _localDataSource.clearCache();
      final navCtx = CoreUtils.rootNavigatorKey.currentContext;
      if (navCtx != null && navCtx.mounted) {
        try {
          // Same reasoning as logoutSession above: this path also ends the
          // session, so the persisted child selection goes with it.
          unawaited(navCtx.read<ParentChildCubit>().resetForLogout());
        } catch (_) {}
        try {
          navCtx.read<RoleCubit>().resetSessionForLogout();
        } catch (_) {}
      }
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError('Failed to clear cache: $e'));
    }
  }

  /// Uses cached staffCode and prefetches the staff profile for the given
  /// organization/school combination using the staff profile controller.
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
      final org = organizationCode.trim();
      final school = schoolCode.trim();
      if (org.isEmpty || school.isEmpty) return;

      // Only run for staff personas in the current org/school context.
      final storage = _storageService;
      final rolesJson = (await storage.getString(StorageKeys.roles) ?? '')
          .trim();
      if (shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: org,
        schoolCode: school,
      )) {
        return;
      }

      final cachedStaffCode =
          (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();
      final cachedStaffOrg =
          (await storage.getString(StorageKeys.staffCodeOrganization) ?? '')
              .trim();
      final cachedStaffSchool =
          (await storage.getString(StorageKeys.staffCodeSchool) ?? '').trim();
      // Only reuse the cached staffCode when it was resolved for the SAME
      // user *and* the same org/school. Otherwise (e.g. the user switched
      // school) it belongs to a different selection and must be re-resolved,
      // or My Profile renders the previous school's staff data.
      final cacheMatchesContext =
          cachedStaffUser == login.userCode &&
          cachedStaffOrg == org &&
          cachedStaffSchool == school;
      String trimmed = cacheMatchesContext ? cachedStaffCode : '';

      final staffRepository = _staffRepository;
      if (trimmed.isEmpty) {
        // Org admins are mapped org-level: the /staff/code lookup expects '-'
        // and 404s on a real school code. The persisted staffCodeSchool below
        // still keeps the real selected school for cache keying.
        final staffLookupSchoolCode = staffCodeLookupSchoolCode(
          rolesJson: rolesJson,
          organizationCode: org,
          schoolCode: school,
        );
        final resolved = await staffRepository.getStaffCodeForUser(
          userCode: login.userCode,
          organizationCode: org,
          schoolCode: staffLookupSchoolCode,
        );
        trimmed = (resolved ?? '').trim();
        if (trimmed.isEmpty) {
          // Resolution failed for this selection: drop the stale staffCode so
          // downstream reads (My Profile, photo upload) don't serve the
          // previous school's code.
          if (!cacheMatchesContext && cachedStaffCode.isNotEmpty) {
            await storage.remove(StorageKeys.staffCode);
            await storage.remove(StorageKeys.staffCodeUser);
            await storage.remove(StorageKeys.staffCodeOrganization);
            await storage.remove(StorageKeys.staffCodeSchool);
          }
          return;
        }
        await storage.saveString(StorageKeys.staffCode, trimmed);
        await storage.saveString(StorageKeys.staffCodeUser, login.userCode);
        await storage.saveString(StorageKeys.staffCodeOrganization, org);
        await storage.saveString(StorageKeys.staffCodeSchool, school);
      }

      // Prefetch staff profile using staff/{code}/profile so
      // profile screens can render from cache.
      try {
        final profile = await staffRepository.getStaffProfile(
          staffCode: trimmed,
          forEditStaff: true,
        );
        await storage.saveString(StorageKeys.staffType, profile.staffType);
        await storage.saveString(
          StorageKeys.staffDesignation,
          profile.designation,
        );
        await storage.saveString(
          StorageKeys.staffAllowedClassroomCodes,
          jsonEncode(profile.allowedClassroomCodes),
        );
        // Also prefetch PIN whenever we prefetch profile for a new org/school.
        try {
          final pin = await staffRepository.getStaffSignInPin(
            staffCode: trimmed,
          );
          if (pin.trim().isNotEmpty) {
            await storage.saveString(StorageKeys.staffPin, pin.trim());
          }
        } catch (_) {}
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
      emit(
        AuthLoaded(
          loginResponse: login,
          schoolsByOrg: prev?.schoolsByOrg ?? const {},
          isPrefetchingSchools: prev?.isPrefetchingSchools ?? false,
          lastErrorMessage: prev?.lastErrorMessage,
          orgNames: names,
          hasLastSchoolFromContext: prev?.hasLastSchoolFromContext ?? false,
          redirectUrl: prev?.redirectUrl,
        ),
      );
    } catch (_) {
      // Non-fatal: keep previous state, org names will fall back to codes
    }
  }
}
