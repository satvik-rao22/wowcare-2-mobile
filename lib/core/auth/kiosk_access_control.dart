import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Owns the kiosk session: whether this device is locked into kiosk mode, which
/// persona verified their PIN, and which routes a kiosk-locked session may
/// reach.
///
/// **This is a service, not a util.** It lives in `core/auth` alongside
/// `TokenRefreshService` and `SessionExpiredCoordinator` because it is session
/// state, it takes [StorageService], and it is consumed from `core`, the
/// router, and several features. It used to sit in
/// `presentation/features/kiosk/utils/`, which inverted the dependency rule —
/// `core/network/auth_interceptor.dart` imported it, i.e. core depended on
/// presentation, on the auth path.
///
/// **All mutable session state is instance state**, held by the single
/// [KioskAccessControl] registered in DI. It was previously `static`, which
/// meant the injected [StorageService] and a set of process-wide globals were
/// two independent sources of truth for who the caller is authenticated as: any
/// code path that constructed a second instance (several did, as an "on demand"
/// fallback) got fresh instance state but *shared* the statics. Resolve the
/// singleton from the service locator — never construct this directly outside
/// DI and tests.
///
/// Reads are served from an in-memory cache so the GoRouter redirect can decide
/// synchronously; storage is only touched on the first check of a process and
/// on writes.
class KioskAccessControl {
  KioskAccessControl(this._storage);

  final StorageService _storage;

  static const String _kioskModeKey = 'kiosk_mode_active';
  static const String _kioskPersonaKey = 'kiosk_user_persona';

  /// Fast, synchronous answer for the router redirect (no async I/O during
  /// navigation).
  bool _kioskModeCached = false;
  String? _kioskPersonaCached;

  /// Whether [_kioskModeCached] has been reconciled with storage at least once
  /// this process, i.e. whether a `false` means "confirmed not a kiosk" rather
  /// than "not looked yet".
  ///
  /// Without this the redirect could not tell those apart: the cache starts
  /// `false`, so every navigation by every non-kiosk user fell through to an
  /// `await` on storage — an async read on the critical path of each
  /// `go`/`push` for the whole session. With it, the read happens once.
  bool _kioskModeResolved = false;

  /// The PIN-verified persona's REAL backend role/code — distinct from the
  /// device account's own role (which may itself be `KIOSK`).
  ///
  /// NOTE: nothing reads these today. They were written for
  /// `AuthInterceptor` to stamp kiosk action calls (sign-in/out) with the
  /// headers the verified staff/guardian actually owns rather than the kiosk
  /// device's identity; that read path was removed in `d3dbd6b8` and the
  /// interceptor's now-unused import of this class was resurrected by merge
  /// `f2801d4f`. The write path below is kept intact so the behaviour can be
  /// restored deliberately — but treat these as write-only until it is.
  String? _verifiedRole;
  String? _verifiedStaffCode;
  String? _verifiedGuardianCode;

  /// Marks the device as kiosk-locked after a successful PIN verification.
  /// Updates storage (persistence) and the cache (fast path) together.
  Future<void> setKioskModeActive(String persona) async {
    await _storage.saveString(_kioskModeKey, 'true');
    await _storage.saveString(_kioskPersonaKey, persona);

    _kioskModeCached = true;
    _kioskPersonaCached = persona;
    _kioskModeResolved = true;

    AppLogger.d(
      '[KioskAccess] Kiosk mode activated: persona=$persona (cache updated)',
    );
  }

  /// Records the real role/code the backend returned for the person who just
  /// verified their PIN. In-memory only: it is re-set on every PIN
  /// verification, so there is nothing stale worth persisting across restarts.
  void setVerifiedIdentity({
    String? role,
    String? staffCode,
    String? guardianCode,
  }) {
    _verifiedRole = _normalize(role);
    _verifiedStaffCode = _normalize(staffCode);
    _verifiedGuardianCode = _normalize(guardianCode);
    AppLogger.d(
      '[KioskAccess] Verified identity set: role=$_verifiedRole '
      'staffCode=$_verifiedStaffCode guardianCode=$_verifiedGuardianCode',
    );
  }

  static String? _normalize(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? get verifiedRole => _verifiedRole;
  String? get verifiedStaffCode => _verifiedStaffCode;
  String? get verifiedGuardianCode => _verifiedGuardianCode;

  /// Whether kiosk mode is active, consulting storage only on a cache miss
  /// (first check of the process, i.e. after an app restart).
  Future<bool> isKioskModeActive() async {
    if (_kioskModeCached) {
      AppLogger.d('[KioskAccess] isKioskModeActive() → cache hit: true');
      return true;
    }

    try {
      final mode = await _storage.getString(_kioskModeKey);
      _kioskModeCached = mode == 'true';
      _kioskModeResolved = true;
      AppLogger.d(
        '[KioskAccess] isKioskModeActive() → storage read: $_kioskModeCached',
      );
      return _kioskModeCached;
    } catch (e) {
      AppLogger.e('[KioskAccess] Error reading kiosk mode from storage: $e');
      // Deliberately NOT marking resolved: an unreadable store leaves the
      // answer unknown, so the next navigation retries rather than caching
      // "not a kiosk" — the router treats unknown as kiosk (fail closed).
      return false;
    }
  }

  /// See [_kioskModeResolved].
  bool get isKioskModeResolved => _kioskModeResolved;

  /// The current kiosk persona (`STAFF` or `GUARDIAN`), cache first.
  Future<String?> getKioskPersona() async {
    if (_kioskPersonaCached != null) {
      AppLogger.d(
        '[KioskAccess] getKioskPersona() → cache hit: $_kioskPersonaCached',
      );
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

  /// Leaves kiosk mode (logout), clearing storage and the cache.
  Future<void> deactivateKioskMode() async {
    await _storage.remove(_kioskModeKey);
    await _storage.remove(_kioskPersonaKey);

    _clearCache();

    AppLogger.d('[KioskAccess] Kiosk mode deactivated (cache cleared)');
  }

  /// Synchronous kiosk check for the GoRouter redirect: returns the cached
  /// value with no storage read, so the redirect cannot race itself.
  bool isKioskModeActiveDirect() {
    AppLogger.d('[KioskAccess] isKioskModeActiveDirect() → $_kioskModeCached');
    return _kioskModeCached;
  }

  /// Clears the in-memory kiosk session synchronously when a
  /// guardian/staff/admin logs in, so stale kiosk state never reaches the
  /// router. Storage is cleared by the async [deactivateKioskMode]; this
  /// covers the synchronous fast path the redirect uses.
  void clearCacheForNonKioskLogin() {
    _clearCache();
    AppLogger.d('[KioskAccess] Cache force-cleared for non-kiosk login');
  }

  void _clearCache() {
    _kioskModeCached = false;
    _kioskPersonaCached = null;
    _verifiedRole = null;
    _verifiedStaffCode = null;
    _verifiedGuardianCode = null;
    _kioskModeResolved = true;
  }

  /// Whether [route] is reachable from a kiosk-locked session.
  ///
  /// Static because it is pure policy over the const list below — it reads no
  /// session state, so it is safe to call without the singleton.
  ///
  /// **The allowlist is evaluated FIRST, and an explicit allow wins over a
  /// prefix block.** It used to be the other way round, which silently made two
  /// entries unreachable: the old `_isBlockedForKiosk` matched the prefix
  /// `/dashboard/staff`, and `'/dashboard/staff-sign-in-form'
  /// .startsWith('/dashboard/staff')` is `true` — so both
  /// `/dashboard/staff-sign-in-form` and `/dashboard/staff-sign-out-form`
  /// returned `false` despite being listed as allowed.
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
