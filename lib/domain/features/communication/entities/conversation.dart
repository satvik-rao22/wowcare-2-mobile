import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final int id;
  final String code;
  final String title;
  final String type;
  final String organizationCode;
  final String schoolCode;
  final String status;
  final String description;
  final String avatarUrl;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final bool privateModeActive;
  final String? privateModeActivatedBy;
  final DateTime? privateModeActivatedAt;
  final int participantCount;
  final int unreadCount;
  final String lastMessagePreview;
  final List<ConversationParticipant> participants;

  const Conversation({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.organizationCode,
    required this.schoolCode,
    required this.status,
    required this.description,
    required this.avatarUrl,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.lastMessageAt,
    this.lastMessageBy,
    this.privateModeActive = false,
    this.privateModeActivatedBy,
    this.privateModeActivatedAt,
    required this.participantCount,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.participants,
  });

  @override
  List<Object?> get props => [
        id,
        code,
        title,
        type,
        organizationCode,
        schoolCode,
        status,
        description,
        avatarUrl,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        lastMessageAt,
        lastMessageBy,
        privateModeActive,
        privateModeActivatedBy,
        privateModeActivatedAt,
        participantCount,
        unreadCount,
        lastMessagePreview,
        participants,
      ];
}

class ConversationParticipant extends Equatable {
  final int id;
  final int conversationId;
  final String userCode;
  final String userName;
  final String role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? lastReadAt;
  final bool muted;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Room Chat Private Mode: true when this participant (a guardian) has
  /// turned Private Mode on for their own messages in this conversation.
  /// Only meaningful for guardian/parent participants.
  final bool privateModeEnabled;

  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userCode,
    required this.userName,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.lastReadAt,
    required this.muted,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.privateModeEnabled = false,
  });

  /// Mirrors [ParticipantEntity.isActive] — `leftAt == null` means still an
  /// active participant; non-null means a Past Participant (read-only
  /// history, cannot send/receive new messages).
  bool get isActive => leftAt == null;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        userCode,
        userName,
        role,
        joinedAt,
        leftAt,
        lastReadAt,
        muted,
        notificationsEnabled,
        createdAt,
        updatedAt,
        privateModeEnabled,
      ];
}

/// One page of the conversation list, mirroring the `StaffPage`/`StudentPage`
/// pattern — carries the backend's own pagination metadata (`hasMore`) so
/// callers don't have to guess from a bare list whether there's more to
/// fetch.
class ConversationsPage extends Equatable {
  const ConversationsPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<Conversation> items;
  final int page;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, hasMore];
}
