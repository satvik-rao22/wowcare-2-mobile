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

  /// Display name of the last message's sender — used to prefix the
  /// conversation list's preview ("SenderName: message"), matching the web
  /// app's chat list. [lastMessageBy] alone is just the raw userCode, not
  /// display-ready.
  final String? lastMessageSenderName;
  final bool privateModeActive;
  final String? privateModeActivatedBy;
  final DateTime? privateModeActivatedAt;
  final int participantCount;
  final int unreadCount;
  final String lastMessagePreview;
  final List<ConversationParticipant> participants;

  /// The last message's sender, resolved to a display name. Prefers
  /// [lastMessageSenderName] (in case the backend ever starts sending it),
  /// but that field is NOT actually present in the real conversation-list
  /// response today (confirmed against a live payload) — [lastMessageBy]
  /// (just a userCode) IS present, and so is [participants], so this
  /// derives the name by matching one against the other instead of
  /// depending on a field the backend doesn't send.
  String? get lastMessageSenderDisplayName {
    final direct = lastMessageSenderName?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final code = lastMessageBy;
    if (code == null || code.isEmpty) return null;
    for (final p in participants) {
      if (p.userCode == code) return p.userName;
    }
    return null;
  }

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
    this.lastMessageSenderName,
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
    lastMessageSenderName,
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

  /// Participant's profile photo — either a resolved URL or a raw
  /// media-asset code, mirroring [ParticipantEntity.avatarUrl].
  final String? avatarUrl;

  /// Role-specific staff code (STF_*) used for fetching the staff profile
  /// photo via DocumentImageWidget. Null for non-staff participants.
  final String? staffCode;

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
    this.avatarUrl,
    this.staffCode,
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
    avatarUrl,
    staffCode,
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
