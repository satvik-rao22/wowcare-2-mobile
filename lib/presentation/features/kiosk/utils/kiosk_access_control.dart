import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Kiosk access control utility.
/// Manages kiosk session state and access control.
/// Uses in-memory cache for fast redirect checks + storage for persistence.
class KioskAccessControl {
  static const String _kioskModeKey = 'kiosk_mode_active';
  static const String _kioskPersonaKey = 'kiosk_user_persona';

  // IN-MEMORY CACHE: Fast, synchronous, atomic checks (no async I/O during navigation)
  static bool _kioskModeCached = false;
  static String? _kioskPersonaCached;

  // The PIN-verified persona's REAL backend role/code — distinct from the
  // device account's own role (which may itself be `KIOSK`). AuthInterceptor
  // uses this for every kiosk action call (sign-in/out, etc.) so those
  // requests carry the headers the verified staff/guardian actually owns,
  // not the kiosk device's own identity. Bootstrap calls (verify-pin,
  // QR fetch) deliberately don't use this — there's no verified persona yet.
  static String? _verifiedRoleCached;
  static String? _verifiedStaffCodeCached;
  static String? _verifiedGuardianCodeCached;

  final StorageService _storage;

  KioskAccessControl(this._storage);

  /// Mark user as kiosk user when PIN verification succeeds.
  /// Updates both storage (persistence) and in-memory cache (fast path).
  Future<void> setKioskModeActive(String persona) async {
    await _storage.saveString(_kioskModeKey, 'true');
    await _storage.saveString(_kioskPersonaKey, persona);

    // UPDATE CACHE IMMEDIATELY (synchronous)
    _kioskModeCached = true;
    _kioskPersonaCached = persona;
    _kioskModeResolved = true;

    AppLogger.d('[KioskAccess] Kiosk mode activated: persona=$persona (cache updated)');
  }

  /// Records the real role/code the backend returned for the person who just
  /// verified their PIN at the kiosk. In-memory only (mirrors the synchronous
  /// cache pattern above) — it's re-set on every PIN verification, so there's
  /// nothing stale to persist to disk across app restarts.
  static void setVerifiedIdentity({
    String? role,
    String? staffCode,
    String? guardianCode,
  }) {
    _verifiedRoleCached = (role ?? '').trim().isEmpty ? null : role!.trim();
    _verifiedStaffCodeCached =
        (staffCode ?? '').trim().isEmpty ? null : staffCode!.trim();
    _verifiedGuardianCodeCached =
        (guardianCode ?? '').trim().isEmpty ? null : guardianCode!.trim();
    AppLogger.d(
      '[KioskAccess] Verified identity set: role=$_verifiedRoleCached '
      'staffCode=$_verifiedStaffCodeCached guardianCode=$_verifiedGuardianCodeCached',
    );
  }

  static String? get verifiedRoleDirect => _verifiedRoleCached;
  static String? get verifiedStaffCodeDirect => _verifiedStaffCodeCached;
  static String? get verifiedGuardianCodeDirect => _verifiedGuardianCodeCached;

  /// Check if kiosk mode is active (uses cache for speed in GoRouter redirect).
  /// Returns cached value immediately on hot path; only reads storage on first check
  /// or after app restart (cache miss).
  Future<bool> isKioskModeActive() async {
    // FAST PATH: Return cached value (eliminates async I/O during navigation)
    if (_kioskModeCached) {
      AppLogger.d('[KioskAccess] isKioskModeActive() → cache hit: true');
      return true;
    }

    // SLOW PATH: Load from storage on first check (app startup)
    try {
      final mode = await _storage.getString(_kioskModeKey);
      _kioskModeCached = mode == 'true';
      _kioskModeResolved = true;
      AppLogger.d('[KioskAccess] isKioskModeActive() → storage read: $_kioskModeCached');
      return _kioskModeCached;
    } catch (e) {
      AppLogger.e('[KioskAccess] Error reading kiosk mode from storage: $e');
      // Deliberately NOT marking resolved: an unreadable store leaves the
      // answer unknown, so the next navigation retries rather than caching
      // "not a kiosk" — the router treats unknown as kiosk (fail closed).
      return false;
    }
  }

  /// Whether the kiosk flag has been read from storage at least once this
  /// process, i.e. whether [isKioskModeActiveDirect]'s `false` means "confirmed
  /// not a kiosk" rather than "not looked yet".
  ///
  /// The router's redirect previously could not tell those apart: the
  /// synchronous cache starts `false`, so on every navigation for every
  /// non-kiosk user it fell through to an `await` on storage — an async read on
  /// the critical path of each `go`/`push` for the entire session. With this,
  /// the storage read happens once and the sync path serves the rest.
  static bool get isKioskModeResolved => _kioskModeResolved;
  static bool _kioskModeResolved = false;

  /// Get current kiosk persona (STAFF or GUARDIAN).
  /// Uses cache when available; only reads storage on cache miss.
  Future<String?> getKioskPersona() async {
    if (_kioskPersonaCached != null) {
      AppLogger.d('[KioskAccess] getKioskPersona() → cache hit: $_kioskPersonaCached');
      return _kioskPersonaCached;
    }

    try {
      final persona = await _storage.getString(_kioskPersonaKey);
      _kioskPersonaCached = persona;
      AppLogger.d('[KioskAccess] getKioskPersona() → storage read: $persona');
      return persona;
    } catch (e) {
      AppLogger.e('[KioskAccess] Error reading kiosk persona from storage: $e');
      return null;
    }
  }

  /// Deactivate kiosk mode (logout).
  /// Clears both storage and in-memory cache.
  Future<void> deactivateKioskMode() async {
    await _storage.remove(_kioskModeKey);
    await _storage.remove(_kioskPersonaKey);

    // CLEAR CACHE IMMEDIATELY
    _kioskModeCached = false;
    _kioskPersonaCached = null;
    _verifiedRoleCached = null;
    _verifiedStaffCodeCached = null;
    _verifiedGuardianCodeCached = null;
    _kioskModeResolved = true;

    AppLogger.d('[KioskAccess] Kiosk mode deactivated (cache cleared)');
  }

  /// SYNCHRONOUS kiosk mode check for GoRouter redirect (no async I/O).
  /// Used by GoRouter.redirect() to avoid race conditions.
  /// Returns the cached value without any storage reads.
  static bool isKioskModeActiveDirect() {
    AppLogger.d('[KioskAccess] isKioskModeActiveDirect() → $_kioskModeCached');
    return _kioskModeCached;
  }

  /// Synchronously clears the in-memory kiosk cache for non-kiosk logins.
  /// Call this when a guardian/staff/admin logs in so stale kiosk state never
  /// reaches the router. Storage is cleared by the async [deactivateKioskMode];
  /// this covers the synchronous fast path used by GoRouter.
  static void clearCacheForNonKioskLogin() {
    _kioskModeCached = false;
    _kioskPersonaCached = null;
    _verifiedRoleCached = null;
    _verifiedStaffCodeCached = null;
    _verifiedGuardianCodeCached = null;
    _kioskModeResolved = true;
    AppLogger.d('[KioskAccess] Static cache force-cleared for non-kiosk login');
  }

  /// Check if given route is allowed for kiosk users.
  ///
  /// **The allowlist is evaluated FIRST, and an explicit allow wins over a
  /// prefix block.** It used to be the other way round, which silently made two
  /// entries unreachable: `_isBlockedForKiosk` matches the prefix
  /// `/dashboard/staff`, and `'/dashboard/staff-sign-in-form'
  /// .startsWith('/dashboard/staff')` is `true` — so both
  /// `/dashboard/staff-sign-in-form` and `/dashboard/staff-sign-out-form`
  /// returned `false` despite being listed as allowed a few lines below.
  ///
  /// Reordering is safe because every allowlist entry is *more specific* than
  /// the block prefix it sits under: `'/dashboard/staff'` (the staff list,
  /// which must stay blocked) does not start with
  /// `'/dashboard/staff-sign-in-form'`, so the block still applies to it.
  static bool isRouteAllowedForKiosk(String route) {
    // Allowed kiosk routes: kiosk-specific paths + attendance/sign-in/sign-out forms
    const allowedRoutes = [
      '/kiosk',
      '/kiosk/',
      // ===== STAFF ROUTES =====
      '/staff-sign-in-form',
      '/staff-sign-out-form',
      '/dashboard/staff-sign-in-form',
      '/dashboard/staff-sign-out-form',
      // ===== UNIFIED GUARDIAN/STUDENT ROUTE (NEW) =====
      '/kiosk/student-sign-in-and-sign-out',
      // ===== LEGACY GUARDIAN/STUDENT ROUTES =====
      '/dashboard/student-selection-sign-in-form',
      '/dashboard/student-selection-sign-out-form',
      '/dashboard/student-sign-in-out-selection',
      '/dashboard/student-attendance-profile',
    ];

    // An explicit allow wins — see the doc comment for why this runs first.
    if (allowedRoutes.any((allowed) => route.startsWith(allowed))) {
      return true;
    }

    // Anything not named above is denied. This is an allowlist, so an unknown
    // or newly-added route is NOT reachable from a kiosk-locked device until
    // someone adds it here deliberately — fail closed, not open.
    //
    // The former `_isBlockedForKiosk` prefix list was removed with this change,
    // not weakened: it only ever ran BEFORE the allowlist, so the sole routes
    // whose outcome it decided were ones that were also allowlisted — the two
    // `/dashboard/staff-sign-*-form` entries it wrongly shadowed. Every route
    // it blocked and did not allow (`/dashboard/students`, `/dashboard/billing`,
    // `/attendance`, `/communication`, …) is still denied here, by the same
    // fall-through that denies everything else. The list is preserved for
    // reference as [blockedRoutesForKiosk] below.
    return false;
  }

  /// Routes that are BLOCKED for kiosk users
  static const blockedRoutesForKiosk = [
    '/dashboard',
    '/attendance',
    '/communication',
    '/notifications',
    '/profile',
    '/settings',
    '/students',
    '/staff',
    '/classroom',
    '/activity-feed',
    '/messages',
    '/billing',
  ];
}
