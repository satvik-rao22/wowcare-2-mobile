import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Unread count for a single conversation for the current user.
class UnreadEntity extends Equatable {
  const UnreadEntity({
    required this.conversationCode,
    required this.conversationType,
    required this.unreadCount,
    required this.organizationCode,
    required this.schoolCode,
    required this.updatedAt,
    this.lastUnreadMessageCode,
    this.lastUnreadAt,
  });

  final String conversationCode;
  final ConversationType conversationType;
  final int unreadCount;
  final String? lastUnreadMessageCode;
  final DateTime? lastUnreadAt;
  final String organizationCode;
  final String schoolCode;
  final DateTime updatedAt;

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [
        conversationCode,
        conversationType,
        unreadCount,
        lastUnreadMessageCode,
        lastUnreadAt,
        organizationCode,
        schoolCode,
        updatedAt,
      ];
}
