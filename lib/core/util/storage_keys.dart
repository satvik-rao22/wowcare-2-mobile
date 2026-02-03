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
  static const String organizationCode = 'organizationCode';
  static const String selectedSchoolName = 'selectedSchoolName';
  static const String loginCompleted = 'loginCompleted';
  static const String onboardingSeen = 'onboardingSeen';
  static const String schoolCode = 'schoolCode';

  // Cache Duration
  static const Duration cacheValidDuration = Duration(minutes: 5);

  // Temporary default until school selection is fully wired
  static const String defaultOrganizationCode = 'ORG_5A8781FD-F';
  static const String defaultSchoolCode = 'SCH_6A96DDD6-0';
}

