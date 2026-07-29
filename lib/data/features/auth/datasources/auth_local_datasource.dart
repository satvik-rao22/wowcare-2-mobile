import 'dart:convert';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/cache/session_local_cache_wiper.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/jwt_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheLoginResponse(LoginResponseModel response);
  Future<LoginResponseModel?> getCachedLoginResponse();
  Future<bool> isCacheValid();
  Future<void> clearCache();
  Future<void> saveLoginContext(Map<String, dynamic> context);
  Future<Map<String, dynamic>?> getLoginContext();
  Future<void> saveCredentials(
    String username,
    String password,
    bool rememberMe,
  );
  Future<Map<String, String?>> getSavedCredentials();
  Future<void> clearCredentials();
  Future<void> saveOrgAndSchoolSelection({
    required String orgCode,
    required String schoolName,
    String? schoolCode,
  });

  /// Saves org/school from login-context API (last school) and marks login completed.
  /// Returns true if context had valid org/school, false otherwise.
  Future<bool> saveOrgAndSchoolFromContext(Map<String, dynamic> context);

  /// Returns list of {organizationCode, schoolCode, schoolName} the user has access to.
  Future<List<Map<String, String>>> getOrganizationsAndSchools();

  /// Saves list of org+school combos. Use when user has multiple.
  Future<void> saveOrganizationsAndSchools(List<Map<String, String>> list);

  /// Sets currently selected org/school for API calls.
  Future<void> setSelectedOrgAndSchool({
    required String organizationCode,
    required String schoolCode,
    String? schoolName,
  });

  /// Persists resolved staffCode for the currently logged-in user.
  Future<void> saveStaffCode({
    required String userCode,
    required String staffCode,
  });

  /// Clears staff/guardian and session caches without logging out (e.g. same-school persona switch).
  Future<void> clearPersonaVolatileCaches();

  /// Sets [activeSchoolRole] and rewrites [StorageKeys.roles] so the active org+school uses only this role.
  Future<void> persistActiveSchoolPersonaRole(String backendRole);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(
    this._storage, {
    SessionLocalCacheWiper? sessionLocalCacheWiper,
  }) : _sessionLocalCacheWiper = sessionLocalCacheWiper;

  final StorageService _storage;
  final SessionLocalCacheWiper? _sessionLocalCacheWiper;

  @override
  Future<void> cacheLoginResponse(LoginResponseModel response) async {
    // Save cache with timestamp
    await _storage.saveJson(StorageKeys.loginCacheKey, response.toJson());
    await _storage.saveInt(
      StorageKeys.loginCacheTimestamp,
      AppTime.nowUtc().millisecondsSinceEpoch,
    );

    // Save individual fields for quick access
    await _storage.saveString(StorageKeys.accessToken, response.accessToken);
    await _storage.saveString(StorageKeys.refreshToken, response.refreshToken);
    await _storage.saveInt(StorageKeys.tokenExpiresIn, response.expiresIn);
    // Mirror the refresh token into the Keychain / EncryptedSharedPreferences
    // (SharedPreferences is plaintext) and record an ABSOLUTE deadline —
    // `expiresIn` is only a duration and can't answer "is it still valid?",
    // which proactive refresh-on-resume needs.
    await TokenRefreshService.instance.saveRefreshToken(response.refreshToken);
    await TokenRefreshService.instance.saveAccessTokenExpiry(
      response.expiresIn,
    );
    await _storage.saveInt(
      StorageKeys.refreshExpiresIn,
      response.refreshExpiresIn,
    );
    await _storage.saveString(StorageKeys.tokenType, response.tokenType);
    await _storage.saveString(StorageKeys.userCode, response.userCode);

    // Extract the JWT `sub` claim — this UUID is what the messaging backend
    // stores as `senderUserCode`.  It differs from `userCode` which is the
    // app-level profile code (USR-…, STF-…, etc.).
    final jwtSub = extractJwtSub(response.accessToken);
    if (jwtSub != null && jwtSub.isNotEmpty) {
      await _storage.saveString(StorageKeys.authUserId, jwtSub);
    }

    await _storage.saveString(StorageKeys.email, response.email);
    await _storage.saveString(StorageKeys.displayName, response.displayName);
    await _storage.saveBool(StorageKeys.firstLogin, response.firstLogin);
    await _storage.saveString(
      StorageKeys.roles,
      jsonEncode(response.roles.map((r) => r.toJson()).toList()),
    );

    // Save org+school list from roles (user may have multiple).
    // Include ORGANIZATION_ADMIN (schoolCode null) so org appears; schools
    // will be fetched via API when user selects that org.
    final orgSchoolList = <Map<String, String>>[];
    for (final r in response.roles) {
      if (r.organizationCode.isEmpty) continue;
      final schoolCode = r.schoolCode.trim();
      final schoolName = r.schoolName.trim();
      final isOrgAdmin = r.role.toUpperCase() == 'ORGANIZATION_ADMIN';
      if (isOrgAdmin) {
        orgSchoolList.add({
          'organizationCode': r.organizationCode,
          'schoolCode': '',
          'schoolName': '',
        });
      } else if (schoolCode.isNotEmpty) {
        orgSchoolList.add({
          'organizationCode': r.organizationCode,
          'schoolCode': schoolCode,
          'schoolName': schoolName,
        });
      }
    }
    if (orgSchoolList.isNotEmpty) {
      await _storage.saveString(
        StorageKeys.organizationsAndSchools,
        jsonEncode(orgSchoolList),
      );
    }
  }

  @override
  Future<LoginResponseModel?> getCachedLoginResponse() async {
    final cached = await _storage.getJson(StorageKeys.loginCacheKey);
    if (cached == null) return null;

    try {
      return LoginResponseModel.fromJson(cached);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isCacheValid() async {
    final timestamp = await _storage.getInt(StorageKeys.loginCacheTimestamp);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = AppTime.nowUtc();
    final difference = now.difference(cacheTime);

    return difference < StorageKeys.cacheValidDuration;
  }

  @override
  Future<void> clearCache() async {
    // Full wipe so every module cache (staff list/profile, activity feed pages,
    // filters, guardian snapshot, timezone, PIN, credentials keys, legacy keys)
    // is cleared and never leaks across users. Preserve first-run onboarding AND
    // the "Remember me" bundle (username + flag) so the sign-in form can still
    // pre-fill after logout / session-expiry. The actual password lives in the
    // biometric-gated secure store (Keychain/Keystore), never here.
    final seenOnboarding =
        await _storage.getBool(StorageKeys.onboardingSeen) ?? false;
    final rememberMe = await _storage.getBool(StorageKeys.rememberMe) ?? false;
    final savedUsername = rememberMe
        ? await _storage.getString(StorageKeys.username)
        : null;
    // CRITICAL: the fresh-install marker must survive logout. It lives in
    // SharedPreferences and is what tells main() this is NOT a fresh install.
    // If it were wiped here, the next cold start would think the app was newly
    // installed and WIPE the Keychain "Remember me" password — which silently
    // broke the whole feature after any logout / session-expiry.
    final installedMarker =
        await _storage.getBool(StorageKeys.appInstalledMarker) ?? false;
    await _storage.clear();
    if (seenOnboarding) {
      await _storage.saveBool(StorageKeys.onboardingSeen, true);
    }
    if (installedMarker) {
      await _storage.saveBool(StorageKeys.appInstalledMarker, true);
    }
    if (rememberMe) {
      await _storage.saveBool(StorageKeys.rememberMe, true);
      if (savedUsername != null && savedUsername.isNotEmpty) {
        await _storage.saveString(StorageKeys.username, savedUsername);
      }
    }
    AppLogger.d(
      '[RememberMe] clearCache → preserved rememberMe=$rememberMe '
      'user="${savedUsername ?? ''}" installMarker=$installedMarker '
      '(password in Keychain is untouched)',
    );
    // The refresh token also lives in the secure store, which `_storage.clear()`
    // does not touch — without this it would survive logout and could renew the
    // previous user's session on a shared device.
    try {
      await TokenRefreshService.instance.clear();
    } catch (_) {}
    try {
      await _sessionLocalCacheWiper?.wipe();
    } catch (_) {}
  }

  @override
  Future<void> saveOrgAndSchoolSelection({
    required String orgCode,
    required String schoolName,
    String? schoolCode,
  }) async {
    final prevOrg =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final prevSchool = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final orgChanged = prevOrg != orgCode.trim();
    await _storage.saveString(StorageKeys.organizationCode, orgCode);
    await _storage.saveString(StorageKeys.selectedSchoolName, schoolName);
    if (schoolCode != null && schoolCode.isNotEmpty) {
      final next = schoolCode.trim();
      final schoolChanged = prevSchool != next;
      if (schoolChanged) {
        await _storage.remove(StorageKeys.schoolTimeZone);
        await _storage.remove(StorageKeys.schoolTimeZoneSchoolCode);
      }
      if (orgChanged || schoolChanged) {
        await _storage.remove(StorageKeys.activeSchoolRole);
      }
      await _storage.saveString(StorageKeys.schoolCode, next);
    } else if (orgChanged) {
      await _storage.remove(StorageKeys.activeSchoolRole);
    }
    await _storage.saveBool(StorageKeys.loginCompleted, true);
  }

  @override
  Future<bool> saveOrgAndSchoolFromContext(Map<String, dynamic> context) async {
    String _str(dynamic v) => (v?.toString().trim() ?? '');
    // Login-context API returns: LastLoginOrganizationCode, LastLoginSchoolCode
    // May also have arrays: OrganizationCodes[], SchoolCodes[] for multiple
    final orgCode = _str(context['LastLoginOrganizationCode']);
    final schoolCode = _str(context['LastLoginSchoolCode']);
    final schoolName = _str(context['schoolName']);
    final displayName = schoolName.isNotEmpty ? schoolName : schoolCode;

    if (orgCode.isEmpty || schoolCode.isEmpty) {
      return false;
    }

    final prevOrg =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final prevSchool = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final schoolChanged = prevSchool != schoolCode;
    final orgChanged = prevOrg != orgCode;
    if (schoolChanged) {
      await _storage.remove(StorageKeys.schoolTimeZone);
      await _storage.remove(StorageKeys.schoolTimeZoneSchoolCode);
    }
    if (schoolChanged || orgChanged) {
      await _storage.remove(StorageKeys.activeSchoolRole);
    }

    // Save selected
    await _storage.saveString(StorageKeys.organizationCode, orgCode);
    await _storage.saveString(StorageKeys.schoolCode, schoolCode);
    await _storage.saveString(StorageKeys.selectedSchoolName, displayName);

    // Merge into organizationsAndSchools list (dedupe by org+school)
    final list = await _getOrganizationsAndSchoolsRaw();
    final entry = <String, String>{
      'organizationCode': orgCode,
      'schoolCode': schoolCode,
      'schoolName': displayName,
    };
    list.removeWhere(
      (e) => e['organizationCode'] == orgCode && e['schoolCode'] == schoolCode,
    );
    list.insert(0, entry); // put current first
    await _storage.saveString(
      StorageKeys.organizationsAndSchools,
      jsonEncode(list),
    );

    await _storage.saveBool(StorageKeys.loginCompleted, true);
    return true;
  }

  List<Map<String, String>> _parseOrgSchoolList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map(
            (e) =>
                (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
          )
          .map(
            (m) => {
              'organizationCode': (m['organizationCode'] ?? '').toString(),
              'schoolCode': (m['schoolCode'] ?? '').toString(),
              'schoolName': (m['schoolName'] ?? m['schoolCode'] ?? '')
                  .toString(),
            },
          )
          .where((m) => m['organizationCode']!.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return _parseOrgSchoolList(decoded);
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<List<Map<String, String>>> _getOrganizationsAndSchoolsRaw() async {
    final raw = await _storage.getString(StorageKeys.organizationsAndSchools);
    if (raw == null || raw.isEmpty) return [];
    try {
      return _parseOrgSchoolList(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Map<String, String>>> getOrganizationsAndSchools() async {
    return _getOrganizationsAndSchoolsRaw();
  }

  @override
  Future<void> saveOrganizationsAndSchools(
    List<Map<String, String>> list,
  ) async {
    await _storage.saveString(
      StorageKeys.organizationsAndSchools,
      jsonEncode(list),
    );
  }

  @override
  Future<void> setSelectedOrgAndSchool({
    required String organizationCode,
    required String schoolCode,
    String? schoolName,
  }) async {
    final prevOrg =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final newOrg = organizationCode.trim();
    final prev = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final next = schoolCode.trim();
    if (prev != next) {
      await _storage.remove(StorageKeys.schoolTimeZone);
      await _storage.remove(StorageKeys.schoolTimeZoneSchoolCode);
    }
    if (prev != next || prevOrg != newOrg) {
      await _storage.remove(StorageKeys.activeSchoolRole);
    }
    await _storage.saveString(StorageKeys.organizationCode, organizationCode);
    await _storage.saveString(StorageKeys.schoolCode, next);
    await _storage.saveString(
      StorageKeys.selectedSchoolName,
      schoolName ?? next,
    );
    if (newOrg.isNotEmpty && next.isNotEmpty) {
      await _storage.saveBool(StorageKeys.loginCompleted, true);
    }
  }

  @override
  Future<void> clearPersonaVolatileCaches() async {
    await _storage.remove(StorageKeys.staffCode);
    await _storage.remove(StorageKeys.staffType);
    await _storage.remove(StorageKeys.staffDesignation);
    await _storage.remove(StorageKeys.staffAllowedClassroomCodes);
    await _storage.remove(StorageKeys.staffCodeUser);
    await _storage.remove(StorageKeys.staffCodeOrganization);
    await _storage.remove(StorageKeys.staffCodeSchool);
    await _storage.remove(StorageKeys.staffPin);
    await _storage.remove(StorageKeys.guardianCode);
    await _storage.remove(StorageKeys.guardianCodeUser);
    await _storage.remove(StorageKeys.guardianCodeSchool);
    await _storage.remove(StorageKeys.guardianCodeOrganization);
    await _storage.remove(StorageKeys.guardianProfileFirstName);
    await _storage.remove(StorageKeys.guardianProfileLastName);
    await _storage.remove(StorageKeys.guardianProfilePhotoUrl);
    await _storage.remove(StorageKeys.guardianProfileAssetCode);
    await _storage.remove(StorageKeys.userAccessDetails);
    try {
      await _sessionLocalCacheWiper?.wipe();
    } catch (_) {}
  }

  @override
  Future<void> persistActiveSchoolPersonaRole(String backendRole) async {
    final org = (await _storage.getString(StorageKeys.organizationCode) ?? '')
        .trim();
    final school = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final normalizedRole = backendRole.trim();
    if (normalizedRole.isEmpty || org.isEmpty || school.isEmpty) return;

    await _storage.saveString(StorageKeys.activeSchoolRole, normalizedRole);

    final raw = await _storage.getString(StorageKeys.roles);
    List<dynamic> list;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        list = decoded is List ? List<dynamic>.from(decoded) : <dynamic>[];
      } catch (_) {
        list = <dynamic>[];
      }
    } else {
      list = <dynamic>[];
    }

    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final o = (m['organizationCode'] ?? '').toString().trim();
      final s = (m['schoolCode'] ?? '').toString().trim();
      if (o == org && s == school) continue;
      out.add(m);
    }
    // Current school first — several screens still read roles.first for display.
    out.insert(0, <String, dynamic>{
      'role': normalizedRole,
      'organizationCode': org,
      'schoolCode': school,
    });
    await _storage.saveString(StorageKeys.roles, jsonEncode(out));
  }

  @override
  Future<void> saveStaffCode({
    required String userCode,
    required String staffCode,
  }) async {
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();

    await _storage.saveString(StorageKeys.staffCode, staffCode);
    await _storage.saveString(StorageKeys.staffCodeUser, userCode);
    await _storage.saveString(
      StorageKeys.staffCodeOrganization,
      organizationCode,
    );
    await _storage.saveString(StorageKeys.staffCodeSchool, schoolCode);
  }

  @override
  Future<void> saveLoginContext(Map<String, dynamic> context) async {
    await _storage.saveJson(StorageKeys.loginContext, context);
  }

  @override
  Future<Map<String, dynamic>?> getLoginContext() async {
    return _storage.getJson(StorageKeys.loginContext);
  }

  @override
  Future<void> saveCredentials(
    String username,
    String password,
    bool rememberMe,
  ) async {
    // SECURITY: the password is never persisted. "Remember me" only stores the
    // username for convenience; the session is restored from the cached
    // access/refresh token, never from saved credentials. Any password value
    // written by a previous app version is purged here.
    await _storage.remove(StorageKeys.legacyPasswordPurgeKey);
    if (rememberMe) {
      await _storage.saveString(StorageKeys.username, username);
    } else {
      await _storage.remove(StorageKeys.username);
    }
    await _storage.saveBool(StorageKeys.rememberMe, rememberMe);
  }

  @override
  Future<Map<String, String?>> getSavedCredentials() async {
    final username = await _storage.getString(StorageKeys.username);
    // SECURITY: passwords are never read back. Purge any legacy stored value.
    await _storage.remove(StorageKeys.legacyPasswordPurgeKey);
    return {'username': username, 'password': null};
  }

  @override
  Future<void> clearCredentials() async {
    await _storage.remove(StorageKeys.username);
    await _storage.remove(StorageKeys.legacyPasswordPurgeKey);
    await _storage.remove(StorageKeys.rememberMe);
  }
}
