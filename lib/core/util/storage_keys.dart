class StorageKeys {
  StorageKeys._();

  // Storage Keys
  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
  static const String tokenExpiresIn = 'tokenExpiresIn';
  static const String refreshExpiresIn = 'refreshExpiresIn';
  static const String tokenType = 'tokenType';
  static const String userCode = 'userCode';
  static const String email = 'email';
  static const String displayName = 'displayName';
  static const String firstLogin = 'firstLogin';
  static const String roles = 'roles';
  static const String rememberMe = 'rememberMe';
  static const String username = 'username';
  static const String password = 'password';
  static const String loginCacheKey = 'login_cache';
  static const String loginCacheTimestamp = 'login_cache_timestamp';
  /// Currently selected org/school (used for API calls).
  static const String organizationCode = 'organizationCode';
  static const String schoolCode = 'schoolCode';
  static const String selectedSchoolName = 'selectedSchoolName';

  /// JSON list of {organizationCode, schoolCode, schoolName} - all org+school combos user has access to.
  static const String organizationsAndSchools = 'organizationsAndSchools';

  static const String loginCompleted = 'loginCompleted';
  static const String onboardingSeen = 'onboardingSeen';
  static const String loginContext = 'loginContext';

  // Cache Duration
  static const Duration cacheValidDuration = Duration(minutes: 5);

  // Temporary default until school selection is fully wired
  // static const String defaultOrganizationCode = 'ORG_FA144927-1';
  // static const String defaultSchoolCode = 'SCH_8A889124-7';
}


