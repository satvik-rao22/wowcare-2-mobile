import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/cubit/feature_flag_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Pure, stateless permission checks for the communication module.
///
/// Depends only on [RoleCubit] and [FeatureFlagCubit] state — no BuildContext,
/// no navigation, no async I/O. Safe to call in GoRouter redirect callbacks.
///
/// Role matrix:
///   admin  → STAFF_DIRECT, ROOM_CHAT, ADMIN_CHAT
///   staff  → STAFF_DIRECT, ROOM_CHAT
///   parent → ROOM_CHAT, ADMIN_CHAT
class CommunicationPermissionService {
  const CommunicationPermissionService({
    required RoleCubit roleCubit,
    required FeatureFlagCubit featureFlagCubit,
  }) : _roleCubit = roleCubit,
       _featureFlagCubit = featureFlagCubit;

  final RoleCubit _roleCubit;
  final FeatureFlagCubit _featureFlagCubit;

  // ─── Master guard ────────────────────────────────────────────────────────────

  /// True when the communication module is enabled AND the user's role is not kiosk.
  bool canAccessCommunication() {
    if (_roleCubit.isKiosk) return false;
    return _featureFlagCubit.state.isCommunicationEnabled;
  }

  // ─── Per-type access ─────────────────────────────────────────────────────────

  /// True when the user's role is allowed to view [type] AND the backing
  /// feature flag is on.
  bool canAccessConversationType(ConversationType type) {
    if (!canAccessCommunication()) return false;
    if (!_roleAllowsType(type)) return false;
    return _flagEnabledForType(type);
  }

  // ─── Create guards ───────────────────────────────────────────────────────────

  /// True when the user can initiate a new conversation of [type].
  /// Same as [canAccessConversationType] — creation requires the same access
  /// as viewing.
  bool canCreateConversation(ConversationType type) =>
      canAccessConversationType(type);

  // ─── Feature-specific guards ─────────────────────────────────────────────────

  /// True when bulk messaging is enabled and the caller is an admin.
  bool canUseBulkMessaging() {
    if (!canAccessCommunication()) return false;
    if (_roleCubit.isParent || _roleCubit.isKiosk) return false;
    return _featureFlagCubit.state.isBulkMessagingEnabled;
  }

  /// True when private mode is enabled for the current user.
  /// Parents and admins/directors can use private mode; staff cannot.
  bool canUsePrivateMode() {
    if (!canAccessCommunication()) return false;
    if (_roleCubit.isKiosk || _roleCubit.isStaff) return false;
    return _featureFlagCubit.state.isPrivateModeEnabled;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  bool _roleAllowsType(ConversationType type) {
    switch (type) {
      case ConversationType.staffDirect:
        // admin + staff only
        return !_roleCubit.isParent && !_roleCubit.isKiosk;
      case ConversationType.roomChat:
        // all roles
        return !_roleCubit.isKiosk;
      case ConversationType.adminChat:
        // admin + parent only
        return !_roleCubit.isStaff && !_roleCubit.isKiosk;
      case ConversationType.classroomChat:
        // staff + admin only (no parents)
        return !_roleCubit.isParent && !_roleCubit.isKiosk;
    }
  }

  bool _flagEnabledForType(ConversationType type) {
    final flags = _featureFlagCubit.state;
    switch (type) {
      case ConversationType.staffDirect:
        return flags.isStaffMessagingEnabled;
      case ConversationType.roomChat:
        return flags.isParentMessagingEnabled;
      case ConversationType.adminChat:
        return flags.isAdminChatEnabled;
      case ConversationType.classroomChat:
        // Classroom chat rides with staff messaging.
        return flags.isStaffMessagingEnabled;
    }
  }
}
