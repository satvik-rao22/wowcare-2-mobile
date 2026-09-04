class StorageKeys {
  StorageKeys._();

  /// Set once on first launch. Lives in SharedPreferences (wiped on iOS/Android
  /// uninstall), so its ABSENCE means a fresh install — used to wipe Keychain
  /// secure credentials that survive uninstall on iOS.
  static const String appInstalledMarker = 'app_installed_marker_v1';

  // Storage Keys
  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
  static const String tokenExpiresIn = 'tokenExpiresIn';

  /// Absolute epoch-ms deadline for the access token. [tokenExpiresIn] alone is
  /// a duration and says nothing about WHEN it was issued, so it cannot answer
  /// "is the token still valid?" — this can, which is what proactive refresh
  /// (refresh-before-expiry on resume) needs.
  static const String tokenExpiresAt = 'tokenExpiresAt';
  static const String refreshExpiresIn = 'refreshExpiresIn';
  static const String tokenType = 'tokenType';
  static const String userCode = 'userCode';

  /// JWT `sub` claim extracted from the access token at login time.
  /// NOTE: the messaging backend stores the USR-/STF-... [userCode] as
  /// `senderUserCode`, not this UUID. Use [userCode] for chat ownership checks.
  static const String authUserId = 'authUserId';

  static const String email = 'email';
  static const String displayName = 'displayName';
  static const String firstLogin = 'firstLogin';
  static const String roles = 'roles';

  /// Backend role for the active org+school when the user has multiple (e.g. STAFF + GUARDIAN).
  static const String activeSchoolRole = 'activeSchoolRole';

  /// The persona (backend role string) the user was last active as, keyed to
  /// [userCode] and stored as `{"userCode": ..., "role": ...}`. Unlike
  /// [activeSchoolRole] — which is cleared on logout and on every org/school
  /// change — this survives logout so a multi-persona account's NEXT fresh
  /// login can reopen the persona they last used instead of always
  /// defaulting to admin/staff. See `AuthLocalDataSourceImpl.clearCache`
  /// (explicitly preserved) and `RoleCubit._computeFallbackRole`.
  static const String lastUsedPersonaRole = 'lastUsedPersonaRole';
  static const String rememberMe = 'rememberMe';
  static const String username = 'username';

  /// SECURITY: the password is NEVER persisted. This key exists only so that
  /// any plaintext value written by an old app version can be located and
  /// purged on login/logout (see AuthLocalDataSource). Do not write to it.
  static const String legacyPasswordPurgeKey = 'password';
  static const String loginCacheKey = 'login_cache';
  static const String loginCacheTimestamp = 'login_cache_timestamp';

  /// Currently selected org/school (used for API calls).
  static const String organizationCode = 'organizationCode';
  static const String schoolCode = 'schoolCode';

  /// Currently selected school's unique code (e.g., 'SCH_...').
  /// Distinct from [schoolName] to avoid ambiguity.
  static const String selectedSchoolCode = 'selectedSchoolCode';
  static const String selectedSchoolName = 'selectedSchoolName';
  static const String schoolName = 'schoolName';

  /// Cached IANA timezone from `GET /api/v1/schools/{code}/timezone` (invalidated when school changes).
  static const String schoolTimeZone = 'schoolTimeZone';
  static const String schoolTimeZoneSchoolCode = 'schoolTimeZoneSchoolCode';

  /// Optional cached staffCode for the logged-in user (when they have a staff profile).
  static const String staffCode = 'staffCode';

  /// Cached staffType from staff profile API (e.g. ORGANIZATION_ADMIN → shown as role).
  static const String staffType = 'staffType';

  /// Cached designation from staff profile API (e.g. ASSOCIATE_TEACHER → shown as role).
  static const String staffDesignation = 'staffDesignation';

  /// JSON array string of classroom codes from staff profile (`allowedClassroomCodes`).
  /// Used to scope attendance APIs for teacher/staff personas.
  static const String staffAllowedClassroomCodes = 'staffAllowedClassroomCodes';

  /// UserCode that owns the cached staffCode; used to invalidate
  /// staffCode when a different user logs in.
  static const String staffCodeUser = 'staffCodeUser';

  /// Org/school context that owns the cached staffCode.
  /// Prevents reusing a staffCode resolved under a different selection.
  static const String staffCodeOrganization = 'staffCodeOrganization';
  static const String staffCodeSchool = 'staffCodeSchool';

  /// Optional cached staff sign-in PIN (from my-profile pin API).
  static const String staffPin = 'staffPin';

  /// Guardian record `code` from `GET /api/v1/guardian/profile` (not the auth userCode).
  static const String guardianCode = 'guardianCode';
  static const String guardianCodeUser = 'guardianCodeUser';
  static const String guardianCodeSchool = 'guardianCodeSchool';
  static const String guardianCodeOrganization = 'guardianCodeOrganization';

  /// Last `GET /api/v1/guardian/profile` snapshot (persisted alongside [guardianCode]).
  static const String guardianProfileFirstName = 'guardianProfileFirstName';
  static const String guardianProfileLastName = 'guardianProfileLastName';
  static const String guardianProfilePhotoUrl = 'guardianProfilePhotoUrl';
  static const String guardianProfileAssetCode = 'guardianProfileAssetCode';

  /// JSON list of {organizationCode, schoolCode, schoolName} - all org+school combos user has access to.
  static const String organizationsAndSchools = 'organizationsAndSchools';

  static const String loginCompleted = 'loginCompleted';
  static const String onboardingSeen = 'onboardingSeen';
  static const String loginContext = 'loginContext';
  static const String userAccessDetails = 'userAccessDetails';

  /// JSON map of Individual Movement filter state (multi-select + optional date range).
  static const String individualMovementFilters =
      'individual_movement_filters_v1';

  // Cache Duration
  static const Duration cacheValidDuration = Duration(minutes: 5);

  /// Activity feed (daily / range) first-page cache — slightly longer to avoid
  /// refetching when switching tabs or returning to the feed screen.
  static const Duration activityFeedCacheDuration = Duration(minutes: 10);

  /// Incremented when activities are created/updated/deleted so cached feed
  /// snapshots are ignored until refetched.
  static const String activityFeedCacheRevision =
      'activity_feed_cache_revision';

  /// Task attachments this device uploaded, as `{seriesCode: [assetRow, …]}`.
  ///
  /// Only needed because the Tasks API exposes no attachments **read** endpoint
  /// (unlike Events/Activities, whose payloads carry their attachment rows), so
  /// without this a file is invisible the moment the in-memory cache is gone.
  /// Display-only — never authoritative for the `assetCodes` full-replace.
  static const String taskAttachmentsCache = 'task_attachments_cache_v1';


}
