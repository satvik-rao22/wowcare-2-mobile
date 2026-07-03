import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

class VisibilityHelper {
  /// Returns true when [viewerCodes] (all known aliases for the current user)
  /// is allowed to see [message]. Staff and admins always see everything.
  /// Private messages are visible only to the sender and the referenced parent.
  static bool canViewMessage(
    MessageEntity message,
    Set<String> viewerCodes,
    bool isStaff,
    bool isAdmin,
  ) {
    if (!message.isPrivate) return true;
    if (isStaff || isAdmin) return true;
    return message.privateParentUserCode != null &&
        viewerCodes.contains(message.privateParentUserCode);
  }
}
