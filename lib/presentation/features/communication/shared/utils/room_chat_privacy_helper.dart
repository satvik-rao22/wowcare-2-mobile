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
