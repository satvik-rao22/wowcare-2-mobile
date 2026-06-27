import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Extends the existing [Conversation] domain model with fields required for
/// the new communication module (v2.1 architecture).
///
/// The existing [Conversation] class is preserved untouched.
/// New repository and cubit code should use [ConversationEntity].
class ConversationEntity extends Equatable {
  const ConversationEntity({
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
    required this.participantCount,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.participants,
    // New fields
    this.studentCode,
    this.classroomCode,
    this.lastMessageAt,
    this.lastMessageBy,
    this.lastMessageSenderName,
    this.privateModeActive = false,
    this.privateModeActivatedBy,
    this.privateModeActivatedAt,
    this.privateModeStates = const {},
  });

  // Core fields (matching existing Conversation entity)
  final int id;
  final String code;
  final String title;
  final ConversationType type;
  final String organizationCode;
  final String schoolCode;
  final String status;
  final String description;
  final String avatarUrl;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int participantCount;
  final int unreadCount;
  final String lastMessagePreview;
  final List<ParticipantEntity> participants;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;

  // New fields for communication v2.1
  /// FK to StudentEntity. Null for STAFF_DIRECT conversations.
  final String? studentCode;

  /// FK to ClassroomEntity. Set only for ROOM_CHAT conversations.
  final String? classroomCode;

  /// Display name of the last message sender (denormalised for list views).
  final String? lastMessageSenderName;

  /// Canonical Room Chat private mode fields.
  final bool privateModeActive;
  final String? privateModeActivatedBy;
  final DateTime? privateModeActivatedAt;

  /// Per-parent private mode states.
  /// Key = parentUserCode, Value = [PrivateModeState].
  /// Empty map means no parent has enabled private mode.
  final Map<String, PrivateModeState> privateModeStates;

  /// Whether any participant currently has private mode enabled.
  bool get hasActivePrivateMode =>
      privateModeActive || privateModeStates.values.any((s) => s.enabled);

  /// Whether private mode is enabled for a specific parent.
  bool isPrivateModeEnabledFor(String parentUserCode) =>
      privateModeStates[parentUserCode]?.enabled ?? false;

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
        participantCount,
        unreadCount,
        lastMessagePreview,
        participants,
        lastMessageAt,
        lastMessageBy,
        lastMessageSenderName,
        privateModeActive,
        privateModeActivatedBy,
        privateModeActivatedAt,
        studentCode,
        classroomCode,
        privateModeStates,
      ];
}

/// A participant in a conversation.
class ParticipantEntity extends Equatable {
  const ParticipantEntity({
    required this.id,
    required this.conversationId,
    required this.userCode,
    required this.userName,
    required this.role,
    required this.joinedAt,
    required this.muted,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.leftAt,
    this.lastReadAt,
    this.avatarUrl,
  });

  final int id;
  final int conversationId;
  final String userCode;
  final String userName;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? lastReadAt;
  final bool muted;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;

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
        avatarUrl,
      ];
}

/// Private mode state for a single parent within a conversation.
class PrivateModeState extends Equatable {
  const PrivateModeState({
    required this.parentCode,
    required this.enabled,
    required this.owner,
    required this.enabledAt,
  });

  /// User code of the parent who owns this private mode slot.
  final String parentCode;

  /// Whether private mode is currently active for this parent.
  final bool enabled;

  /// User code of the person who enabled private mode.
  /// Only this user (or an admin/director) can disable it.
  final String owner;

  final DateTime enabledAt;

  @override
  List<Object?> get props => [parentCode, enabled, owner, enabledAt];
}
