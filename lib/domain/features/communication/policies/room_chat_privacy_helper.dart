import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

/// Who is viewing a ROOM_CHAT thread — determines private-message visibility.
enum RoomChatViewerRole { guardian, staffOrAdmin }

/// Identifies the viewer of a ROOM_CHAT conversation for privacy checks.
class RoomChatPrivacyContext {
  const RoomChatPrivacyContext({
    required this.conversationType,
    required this.viewerRole,
    required this.viewerUserCode,
  });

  final ConversationType conversationType;
  final RoomChatViewerRole viewerRole;
  final String viewerUserCode;
}

/// Centralizes the private-mode visibility rule that's otherwise duplicated
/// inline across every ParentMessagingThread guardian-tab block: staff/admin
/// see every private message in the room; a guardian only sees the ones
/// scoped to them.
class RoomChatPrivacyHelper {
  const RoomChatPrivacyHelper._();

  static bool canViewerSeeMessage({
    required RoomChatPrivacyContext context,
    required bool isPrivate,
    String? privateParentUserCode,
  }) {
    if (!isPrivate) return true;
    if (context.viewerRole == RoomChatViewerRole.staffOrAdmin) return true;
    return privateParentUserCode == context.viewerUserCode;
  }

  /// Whether [viewerRole] is allowed to flip a ROOM_CHAT conversation's
  /// Private Mode toggle. Only the guardian persona may enable/disable
  /// Private Mode — staff, admin, director, educator, assistant, and any
  /// future non-guardian role must never be able to. Single source of truth
  /// for this rule so it can be enforced both in the UI (hide/disable the
  /// control) and in the business layer (refuse the mutation even if a
  /// caller manages to invoke it anyway).
  static bool canModifyPrivateMode(RoomChatViewerRole viewerRole) =>
      viewerRole == RoomChatViewerRole.guardian;

  /// Filters [messages] down to what a guardian should see in their merged
  /// thread view: every public message, plus only the private messages
  /// scoped to [currentGuardianUserCode].
  static List<Message> messagesForGuardianMergedThread({
    required List<Message> messages,
    required String currentGuardianUserCode,
  }) {
    return messages
        .where(
          (m) =>
              !m.isPrivate || m.privateParentUserCode == currentGuardianUserCode,
        )
        .toList();
  }
}
