import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Kiosk access control utility.
/// Manages kiosk session state and access control.
class KioskAccessControl {
  static const String _kioskModeKey = 'kiosk_mode_active';
  static const String _kioskPersonaKey = 'kiosk_user_persona';

  final StorageService _storage;

  KioskAccessControl(this._storage);

  /// Mark user as kiosk user when PIN verification succeeds
  Future<void> setKioskModeActive(String persona) async {
    await _storage.saveString(_kioskModeKey, 'true');
    await _storage.saveString(_kioskPersonaKey, persona);
    AppLogger.d('[KioskAccess] Kiosk mode activated: persona=$persona');
  }

  /// Check if kiosk mode is active
  Future<bool> isKioskModeActive() async {
    final mode = await _storage.getString(_kioskModeKey);
    return mode == 'true';
  }

  /// Get current kiosk persona (STAFF or GUARDIAN)
  Future<String?> getKioskPersona() async {
    return await _storage.getString(_kioskPersonaKey);
  }

  /// Deactivate kiosk mode (logout)
  Future<void> deactivateKioskMode() async {
    await _storage.remove(_kioskModeKey);
    await _storage.remove(_kioskPersonaKey);
    AppLogger.d('[KioskAccess] Kiosk mode deactivated');
  }

  /// Check if given route is allowed for kiosk users
  static bool isRouteAllowedForKiosk(String route) {
    // Allowed kiosk routes only
    const allowedRoutes = [
      '/kiosk',
      '/kiosk/student-sign-in',
      '/kiosk/student-sign-out',
      '/kiosk/student-sign-in-out',
      '/kiosk/staff-sign-in',
      '/kiosk/staff-sign-out',
      '/staff-sign-in-form',
      '/staff-sign-out-form',
      '/dashboard/staff-sign-in-form',
      '/dashboard/staff-sign-out-form',
    ];

    return allowedRoutes.any((allowed) => route.startsWith(allowed));
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
