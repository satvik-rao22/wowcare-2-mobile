import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'communication_permission_service.dart';

/// GoRouter-compatible redirect helpers for communication routes.
///
/// All methods are synchronous so they can be called directly inside
/// GoRouter's `redirect` callback without `await`.
///
/// Usage in GoRouter:
/// ```dart
/// redirect: (context, state) {
///   final guards = context.read<CommunicationRouteGuards>();
///   return guards.redirectIfNoAccess(state.uri.path);
/// }
/// ```
class CommunicationRouteGuards {
  const CommunicationRouteGuards({
    required CommunicationPermissionService permissionService,
    String fallbackRoute = '/dashboard',
  })  : _permissions = permissionService,
        _fallbackRoute = fallbackRoute;

  final CommunicationPermissionService _permissions;

  /// Route to redirect to when access is denied.
  final String _fallbackRoute;

  // ─── Master guard ────────────────────────────────────────────────────────────

  /// Returns [_fallbackRoute] when the user cannot access the communication
  /// module at all, otherwise null (allow navigation).
  ///
  /// Wire to GoRouter's top-level `redirect` for any `/communication/*` route.
  String? redirectIfNoAccess(String currentPath) {
    if (!_permissions.canAccessCommunication()) return _fallbackRoute;
    return null;
  }

  // ─── Per-type guards ─────────────────────────────────────────────────────────

  /// Returns [_fallbackRoute] when the user cannot access [type], otherwise null.
  ///
  /// ```dart
  /// redirect: (context, state) =>
  ///   guards.redirectIfCannotAccessType(ConversationType.staffDirect),
  /// ```
  String? redirectIfCannotAccessType(ConversationType type) {
    if (!_permissions.canAccessConversationType(type)) return _fallbackRoute;
    return null;
  }

  /// Redirect guard for STAFF_DIRECT routes.
  String? redirectIfCannotAccessStaffDirect() =>
      redirectIfCannotAccessType(ConversationType.staffDirect);

  /// Redirect guard for ROOM_CHAT routes.
  String? redirectIfCannotAccessRoomChat() =>
      redirectIfCannotAccessType(ConversationType.roomChat);

  /// Redirect guard for ADMIN_CHAT routes.
  String? redirectIfCannotAccessAdminChat() =>
      redirectIfCannotAccessType(ConversationType.adminChat);

  // ─── Feature guards ──────────────────────────────────────────────────────────

  /// Returns [_fallbackRoute] when bulk messaging is not available.
  String? redirectIfCannotUseBulkMessaging() {
    if (!_permissions.canUseBulkMessaging()) return _fallbackRoute;
    return null;
  }

  // ─── Convenience booleans (for conditional UI in route builders) ─────────────

  bool get canAccessCommunication => _permissions.canAccessCommunication();

  bool canAccessType(ConversationType type) =>
      _permissions.canAccessConversationType(type);

  bool get canAccessStaffDirect =>
      _permissions.canAccessConversationType(ConversationType.staffDirect);

  bool get canAccessRoomChat =>
      _permissions.canAccessConversationType(ConversationType.roomChat);

  bool get canAccessAdminChat =>
      _permissions.canAccessConversationType(ConversationType.adminChat);

  bool get canUseBulkMessaging => _permissions.canUseBulkMessaging();

  bool get canUsePrivateMode => _permissions.canUsePrivateMode();
}
