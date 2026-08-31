import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

class VisibilityHelper {
  static bool canViewMessage(
    MessageEntity message,
    String viewerUserCode,
    bool isStaff,
    bool isAdmin,
  ) {
    if (!message.isPrivate) return true;

    if (isStaff || isAdmin) {
      return true;
    }

    return message.privateParentUserCode == viewerUserCode;
  }
}
