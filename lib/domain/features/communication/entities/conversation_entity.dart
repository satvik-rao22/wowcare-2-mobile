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
    this.studentStatus,
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

  /// Enrollment status of [studentCode] (e.g. `ACTIVE`, `UPCOMING`,
  /// `INACTIVE`) — sent as a top-level field alongside `studentCode`/
  /// `studentName`. Null for conversation types that aren't student-scoped.
  final String? studentStatus;

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

  /// The last message's sender, resolved to a display name. Prefers
  /// [lastMessageSenderName] (in case the backend ever starts sending it —
  /// the DTO already parses it), but that field is NOT actually present in
  /// the real `/conversations/type/{TYPE}` list response today (confirmed
  /// against a live payload) — [lastMessageBy] (just a userCode) IS
  /// present, and so is the full [participants] array, so this derives the
  /// name by matching one against the other instead of depending on a
  /// field the backend doesn't send.
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

  /// `lastMessageSenderName` and `unreadCount` are overridable — added for
  /// [ConversationListCubit]'s cross-source reconciliation (carrying a
  /// known-good sender name forward when a later, less-complete update
  /// would otherwise blank it out for the same message) and for resolving
  /// the real per-user unread count out of `participants[]` (see
  /// [ConversationEntityRepositoryImpl._resolveUnreadCounts]). Extend with
  /// more fields if another caller needs them.
  ConversationEntity copyWith({
    String? lastMessageSenderName,
    int? unreadCount,
  }) {
    return ConversationEntity(
      id: id,
      code: code,
      title: title,
      type: type,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      status: status,
      description: description,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      participantCount: participantCount,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessagePreview: lastMessagePreview,
      participants: participants,
      lastMessageAt: lastMessageAt,
      lastMessageBy: lastMessageBy,
      studentCode: studentCode,
      studentStatus: studentStatus,
      classroomCode: classroomCode,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      privateModeActive: privateModeActive,
      privateModeActivatedBy: privateModeActivatedBy,
      privateModeActivatedAt: privateModeActivatedAt,
      privateModeStates: privateModeStates,
    );
  }

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
    studentStatus,
    classroomCode,
    privateModeStates,
  ];
}

/// A participant in a conversation.
///
/// [userCode] is the single canonical identifier the messaging service
/// actually keys on (the `USR-...` code) — it's always present. The
/// role-specific codes ([staffCode], [guardianCode], [adminCode]) and
/// [organizationCode]/[schoolCode] are optional: the backend payload doesn't
/// currently send them, so they parse as null today. They're modeled here
/// so that the day the backend adds them to the participant JSON, this
/// entity (and every screen reading from it) picks them up with no further
/// Flutter changes — display/identity logic should never rely on
/// [userName] alone, since display names aren't unique.
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
    this.staffCode,
    this.guardianCode,
    this.adminCode,
    this.organizationCode,
    this.schoolCode,
    this.unreadCount = 0,
    this.active = true,
    this.staffStatus,
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
  final String? staffCode;
  final String? guardianCode;
  final String? adminCode;
  final String? organizationCode;
  final String? schoolCode;

  /// This participant's own employment status (e.g. `ACTIVE`, `UPCOMING`,
  /// `INACTIVE`) when they're a staff member — the STAFF_DIRECT equivalent
  /// of [ConversationEntity.studentStatus], but per-participant rather
  /// than conversation-level since a STAFF_DIRECT chat's "subject" is one
  /// of the two participants, not the conversation itself. Null for
  /// non-staff participants (e.g. guardians) or when not sent.
  final String? staffStatus;

  /// This participant's own unread count for the conversation — the REST
  /// `/conversations/type/{TYPE}` list nests the real per-user unread count
  /// here rather than on the conversation itself. See
  /// [ConversationEntityRepositoryImpl._resolveUnreadCounts].
  final int unreadCount;

  /// Backend-authoritative "still active" flag, sent alongside (and
  /// independent of) [leftAt] — a participant can be deactivated for a
  /// reason other than leaving (e.g. `deactivatedReason`) while [leftAt]
  /// stays null, so this must be checked too, not just [leftAt].
  final bool active;

  /// `leftAt == null` is the canonical "still an active participant" check
  /// — set the instant the backend marks them as removed (classroom
  /// unassigned, guardian removed, admin/director role revoked, etc.). A
  /// non-null [leftAt] means this is a **Past Participant**: visible in
  /// history with original attribution, but excluded from send/receive.
  /// Combined with [active] since the backend can also deactivate a
  /// participant without setting [leftAt].
  bool get isActive => leftAt == null && active;

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
    active,
    staffCode,
    guardianCode,
    adminCode,
    organizationCode,
    schoolCode,
    unreadCount,
    staffStatus,
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
