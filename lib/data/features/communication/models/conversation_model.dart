import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';

part 'conversation_model.g.dart';

// ── Field-quirk helpers (were inline expressions in the old parser) ──────────

/// ROOM_CHAT sends a resolved `studentName` that is more reliable than
/// `title` (which can fall back to a raw studentCode). Prefer it when present.
/// Both values are trimmed, matching the previous hand-written parser.
Object? _readConversationTitle(Map<dynamic, dynamic> json, String key) {
  final studentName = (json['studentName'] as String?)?.trim();
  final rawTitle = (json['title'] as String?)?.trim() ?? '';
  return (studentName != null && studentName.isNotEmpty)
      ? studentName
      : rawTitle;
}

/// New API sends `displayName`; old API sent `userName`. Accept both, preferring
/// a non-empty `displayName`.
Object? _readParticipantUserName(Map<dynamic, dynamic> json, String key) {
  final displayName = json['displayName'] as String?;
  if (displayName != null && displayName.isNotEmpty) return displayName;
  return json['userName'] as String? ?? '';
}

/// New API sends `participantType`; old API sent `role`. Accept both, default
/// `STAFF`.
Object? _readParticipantRole(Map<dynamic, dynamic> json, String key) {
  return (json['participantType'] as String?) ??
      (json['role'] as String?) ??
      'STAFF';
}

/// First non-empty (trimmed) value, or null when there is none.
String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v;
  }
  return null;
}

/// The participant's profile photo — a resolved URL or a raw media-asset code,
/// depending on which field the backend populates. Same field precedence the
/// v2 `ParticipantEntityDto` already reads; this parser dropped the photo
/// altogether, which is why the staff-messaging inbox could only ever render
/// initials even when the payload carried one.
Object? _readParticipantAvatar(Map<dynamic, dynamic> json, String key) =>
    _firstNonEmpty([
      json['photoUrl'] as String?,
      json['avatarUrl'] as String?,
      json['profilePhotoUrl'] as String?,
      (json['user'] as Map<String, dynamic>?)?['photoUrl'] as String?,
      json['profileAssetCode'] as String?,
      json['profilePhotoAssetCode'] as String?,
    ]);

/// `DateTime.parse` with a fallback to now when the value is absent — matches
/// the old parser's `!= null ? DateTime.parse(...) : AppTime.nowUtc()`.
DateTime _dateOrNow(Object? value) =>
    value != null ? DateTime.parse(value as String) : AppTime.nowUtc();

/// Lenient parse used only for `privateModeActivatedAt` — the old parser used
/// `DateTime.tryParse` here (null on unparseable) rather than `DateTime.parse`.
DateTime? _dateTryParseOrNull(Object? value) =>
    value != null ? DateTime.tryParse(value as String) : null;

/// API model for a conversation. Standalone DTO (mandate: not an entity);
/// [toEntity] maps it to the pure-Dart [Conversation]. `@JsonKey` defaults and
/// the `readValue`/`fromJson` helpers above reproduce the previous
/// hand-written `fromJson`/`toJson` behaviour exactly.
@JsonSerializable(explicitToJson: true)
class ConversationModel {
  const ConversationModel({
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
    this.studentStatus,
    this.classroomCode,
  });

  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(defaultValue: '')
  final String code;

  @JsonKey(readValue: _readConversationTitle)
  final String title;

  @JsonKey(defaultValue: 'DIRECT')
  final String type;
  @JsonKey(defaultValue: '')
  final String organizationCode;
  @JsonKey(defaultValue: '')
  final String schoolCode;
  @JsonKey(defaultValue: 'ACTIVE')
  final String status;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: '')
  final String avatarUrl;

  @JsonKey(fromJson: _dateOrNow)
  final DateTime createdAt;
  @JsonKey(defaultValue: '')
  final String createdBy;
  @JsonKey(fromJson: _dateOrNow)
  final DateTime updatedAt;
  @JsonKey(defaultValue: '')
  final String updatedBy;

  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final String? lastMessageSenderName;

  @JsonKey(defaultValue: false)
  final bool privateModeActive;
  final String? privateModeActivatedBy;

  @JsonKey(fromJson: _dateTryParseOrNull)
  final DateTime? privateModeActivatedAt;

  @JsonKey(defaultValue: 0)
  final int participantCount;
  @JsonKey(defaultValue: 0)
  final int unreadCount;
  @JsonKey(defaultValue: '')
  final String lastMessagePreview;

  @JsonKey(defaultValue: [])
  final List<ConversationParticipantModel> participants;

  @JsonKey(includeIfNull: false)
  final String? studentStatus;
  @JsonKey(includeIfNull: false)
  final String? classroomCode;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  Conversation toEntity() => Conversation(
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
    lastMessageAt: lastMessageAt,
    lastMessageBy: lastMessageBy,
    lastMessageSenderName: lastMessageSenderName,
    privateModeActive: privateModeActive,
    privateModeActivatedBy: privateModeActivatedBy,
    privateModeActivatedAt: privateModeActivatedAt,
    participantCount: participantCount,
    unreadCount: unreadCount,
    lastMessagePreview: lastMessagePreview,
    participants: participants.map((e) => e.toEntity()).toList(),
    studentStatus: studentStatus,
    classroomCode: classroomCode,
  );
}

@JsonSerializable()
class ConversationParticipantModel {
  const ConversationParticipantModel({
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
    this.unreadCount = 0,
    this.active = true,
    this.staffStatus,
    this.avatarUrl,
    this.staffCode,
  });

  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(defaultValue: 0)
  final int conversationId;
  @JsonKey(defaultValue: '')
  final String userCode;

  @JsonKey(readValue: _readParticipantUserName)
  final String userName;

  @JsonKey(readValue: _readParticipantRole)
  final String role;

  @JsonKey(fromJson: _dateOrNow)
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? lastReadAt;

  @JsonKey(defaultValue: false)
  final bool muted;
  @JsonKey(defaultValue: true)
  final bool notificationsEnabled;

  @JsonKey(fromJson: _dateOrNow)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateOrNow)
  final DateTime updatedAt;

  @JsonKey(defaultValue: false)
  final bool privateModeEnabled;
  @JsonKey(defaultValue: 0)
  final int unreadCount;
  @JsonKey(defaultValue: true)
  final bool active;
  @JsonKey(includeIfNull: false)
  final String? staffStatus;

  /// Resolved URL or raw media-asset code — see [_readParticipantAvatar].
  @JsonKey(readValue: _readParticipantAvatar, includeIfNull: false)
  final String? avatarUrl;

  /// `STF_*` for a staff participant. Not sent by every backend build; parsed
  /// defensively so the avatar can use it the moment it appears (until then
  /// the photo is resolved from [userCode] instead).
  @JsonKey(includeIfNull: false)
  final String? staffCode;

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationParticipantModelToJson(this);

  ConversationParticipant toEntity() => ConversationParticipant(
    id: id,
    conversationId: conversationId,
    userCode: userCode,
    userName: userName,
    role: role,
    joinedAt: joinedAt,
    leftAt: leftAt,
    lastReadAt: lastReadAt,
    muted: muted,
    notificationsEnabled: notificationsEnabled,
    createdAt: createdAt,
    updatedAt: updatedAt,
    privateModeEnabled: privateModeEnabled,
    unreadCount: unreadCount,
    active: active,
    staffStatus: staffStatus,
    avatarUrl: avatarUrl,
    staffCode: staffCode,
  );
}
