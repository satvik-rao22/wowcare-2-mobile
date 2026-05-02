import 'dart:convert';
import 'package:wowcare/core/cache/session_local_cache_wiper.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheLoginResponse(LoginResponseModel response);
  Future<LoginResponseModel?> getCachedLoginResponse();
  Future<bool> isCacheValid();
  Future<void> clearCache();
  Future<void> saveLoginContext(Map<String, dynamic> context);
  Future<Map<String, dynamic>?> getLoginContext();
  Future<void> saveCredentials(String username, String password, bool rememberMe);
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
      DateTime.now().millisecondsSinceEpoch,
    );

    // Save individual fields for quick access
    await _storage.saveString(StorageKeys.accessToken, response.accessToken);
    await _storage.saveString(StorageKeys.refreshToken, response.refreshToken);
    await _storage.saveInt(StorageKeys.tokenExpiresIn, response.expiresIn);
    await _storage.saveInt(StorageKeys.refreshExpiresIn, response.refreshExpiresIn);
    await _storage.saveString(StorageKeys.tokenType, response.tokenType);
    await _storage.saveString(StorageKeys.userCode, response.userCode);
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
      final isOrgAdmin =
          r.role.toUpperCase() == 'ORGANIZATION_ADMIN';
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
          'schoolName': schoolCode,
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
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference < StorageKeys.cacheValidDuration;
  }

  @override
  Future<void> clearCache() async {
    // Full wipe so every module cache (staff list/profile, activity feed pages,
    // filters, guardian snapshot, timezone, PIN, credentials keys, legacy keys)
    // is cleared and never leaks across users. Preserve first-run onboarding only.
    final seenOnboarding =
        await _storage.getBool(StorageKeys.onboardingSeen) ?? false;
    await _storage.clear();
    if (seenOnboarding) {
      await _storage.saveBool(StorageKeys.onboardingSeen, true);
    }
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
    final prevSchool =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    await _storage.saveString(StorageKeys.organizationCode, orgCode);
    await _storage.saveString(StorageKeys.selectedSchoolName, schoolName);
    if (schoolCode != null && schoolCode.isNotEmpty) {
      final next = schoolCode.trim();
      if (prevSchool != next) {
        await _storage.remove(StorageKeys.schoolTimeZone);
        await _storage.remove(StorageKeys.schoolTimeZoneSchoolCode);
      }
      await _storage.saveString(StorageKeys.schoolCode, next);
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
    final displayName =
        schoolName.isNotEmpty ? schoolName : schoolCode;

    if (orgCode.isEmpty || schoolCode.isEmpty) {
      return false;
    }

    final prevSchool =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (prevSchool != schoolCode) {
      await _storage.remove(StorageKeys.schoolTimeZone);
      await _storage.remove(StorageKeys.schoolTimeZoneSchoolCode);
    }

    // Save selected
    await _storage.saveString(StorageKeys.organizationCode, orgCode);
    await _storage.saveString(StorageKeys.schoolCode, schoolCode);
    await _storage.saveString(
      StorageKeys.selectedSchoolName,
      displayName,
    );

    // Merge into organizationsAndSchools list (dedupe by org+school)
    final list = await _getOrganizationsAndSchoolsRaw();
    final entry = <String, String>{
      'organizationCode': orgCode,
      'schoolCode': schoolCode,
      'schoolName': displayName,
    };
    list.removeWhere((e) =>
        e['organizationCode'] == orgCode && e['schoolCode'] == schoolCode);
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
          .map((e) => (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
          .map((m) => {
                'organizationCode': (m['organizationCode'] ?? '').toString(),
                'schoolCode': (m['schoolCode'] ?? '').toString(),
                'schoolName': (m['schoolName'] ?? m['schoolCode'] ?? '').toString(),
              })
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
      List<Map<String, String>> list) async {
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
    final prev =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final next = schoolCode.trim();
    if (prev != next) {
      await _storage.remove(StorageKeys.schoolTimeZone);
      await _storage.remove(StorageKeys.schoolTimeZoneSchoolCode);
    }
    await _storage.saveString(StorageKeys.organizationCode, organizationCode);
    await _storage.saveString(StorageKeys.schoolCode, next);
    await _storage.saveString(
      StorageKeys.selectedSchoolName,
      schoolName ?? next,
    );
  }

  @override
  Future<void> saveStaffCode({
    required String userCode,
    required String staffCode,
  }) async {
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

    await _storage.saveString(StorageKeys.staffCode, staffCode);
    await _storage.saveString(StorageKeys.staffCodeUser, userCode);
    await _storage.saveString(
      StorageKeys.staffCodeOrganization,
      organizationCode,
    );
    await _storage.saveString(
      StorageKeys.staffCodeSchool,
      schoolCode,
    );
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
  Future<void> saveCredentials(String username, String password, bool rememberMe) async {
    if (rememberMe) {
      await _storage.saveString(StorageKeys.username, username);
      await _storage.saveString(StorageKeys.password, password);
    } else {
      await _storage.remove(StorageKeys.username);
      await _storage.remove(StorageKeys.password);
    }
    await _storage.saveBool(StorageKeys.rememberMe, rememberMe);
  }

  @override
  Future<Map<String, String?>> getSavedCredentials() async {
    final username = await _storage.getString(StorageKeys.username);
    final password = await _storage.getString(StorageKeys.password);
    return {
      'username': username,
      'password': password,
    };
  }

  @override
  Future<void> clearCredentials() async {
    await _storage.remove(StorageKeys.username);
    await _storage.remove(StorageKeys.password);
    await _storage.remove(StorageKeys.rememberMe);
  }
}
