import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'communication_permission_service.dart';

/// Derives drawer / navigation-menu visibility from [CommunicationPermissionService].
///
/// Each getter maps directly to one menu entry. The UI reads these booleans to
/// show or hide items — no business logic lives in the widget tree.
///
///   Admin  → Staff Messaging + Parent Messaging + Admin Chat
///   Staff  → Staff Messaging + Parent Messaging
///   Parent → Parent Messaging + Admin Chat
class CommunicationMenuVisibilityService {
  const CommunicationMenuVisibilityService({
    required CommunicationPermissionService permissionService,
  }) : _permissions = permissionService;

  final CommunicationPermissionService _permissions;

  /// Show "Staff Messaging" entry (STAFF_DIRECT).
  bool get showStaffMessaging =>
      _permissions.canAccessConversationType(ConversationType.staffDirect);

  /// Show "Parent Messaging" entry (ROOM_CHAT).
  bool get showParentMessaging =>
      _permissions.canAccessConversationType(ConversationType.roomChat);

  /// Show "Admin Chat" entry (ADMIN_CHAT).
  bool get showAdminChat =>
      _permissions.canAccessConversationType(ConversationType.adminChat);

  /// True when at least one communication menu entry is visible.
  /// Use to decide whether to show the Communication section header at all.
  bool get hasAnyCommunicationEntry =>
      showStaffMessaging || showParentMessaging || showAdminChat;

  /// Ordered list of [ConversationType] the current user can see in the menu.
  /// Useful for tab-bar or segmented-control renderers.
  List<ConversationType> get visibleConversationTypes {
    return [
      if (showStaffMessaging) ConversationType.staffDirect,
      if (showParentMessaging) ConversationType.roomChat,
      if (showAdminChat) ConversationType.adminChat,
    ];
  }
}
