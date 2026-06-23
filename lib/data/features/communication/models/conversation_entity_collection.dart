import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

part 'conversation_entity_collection.g.dart';

/// Isar collection backing [ConversationEntity].
///
/// Named [ConversationEntityCollection] to avoid collision with the existing
/// [ConversationCollection] which backs the legacy [Conversation] entity.
///
/// IMPORTANT: Do NOT touch [ConversationCollection] — it is still used by
/// the existing messaging screens. New cubits and repositories use this class.
@collection
class ConversationEntityCollection {
  Id get isarId => id;

  late int id;

  @Index(unique: true)
  late String code;

  /// Raw string stored; convert via [ConversationType.fromApiString].
  @Index()
  late String type;

  // Student / classroom context (null for STAFF_DIRECT)
  @Index()
  String? studentCode;
  String? classroomCode;

  // Core metadata
  late String title;
  late String description;
  late String avatarUrl;
  late String status;
  late String createdBy;
  late String updatedBy;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Last-message denormalisation for list views
  @Index()
  DateTime? lastMessageAt;
  String? lastMessageBy;
  String? lastMessageSenderName;
  late String lastMessagePreview;
  bool privateModeActive = false;
  String? privateModeActivatedBy;
  DateTime? privateModeActivatedAt;

  late int participantCount;
  late int unreadCount;

  // Participants stored as embedded list
  List<ParticipantEntityCollection>? participants;

  // Private mode: stored as JSON string
  // Decoded at read-time into Map<String, PrivateModeState>
  String? privateModeStatesJson;

  // Tenancy — required on every query
  @Index()
  late String organizationCode;

  @Index()
  late String schoolCode;

  // Sync metadata
  bool localOnly = false;
  bool pendingDelete = false;
  DateTime? lastSyncedAt;

  ConversationEntityCollection();

  // ─── Composite indexes ─────────────────────────────────────────────────────
  // The generated .g.dart file will use these via @Index annotations above.
  // Composite(schoolCode, type, lastMessageAt) used for list queries.

  // ─── Mapping ───────────────────────────────────────────────────────────────

  factory ConversationEntityCollection.fromEntity(ConversationEntity entity) {
    return ConversationEntityCollection()
      ..id = entity.id
      ..code = entity.code
      ..type = entity.type.toApiString()
      ..studentCode = entity.studentCode
      ..classroomCode = entity.classroomCode
      ..title = entity.title
      ..description = entity.description
      ..avatarUrl = entity.avatarUrl
      ..status = entity.status
      ..createdBy = entity.createdBy
      ..updatedBy = entity.updatedBy
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..lastMessageAt = entity.lastMessageAt
      ..lastMessageBy = entity.lastMessageBy
      ..lastMessageSenderName = entity.lastMessageSenderName
      ..lastMessagePreview = entity.lastMessagePreview
      ..privateModeActive = entity.privateModeActive
      ..privateModeActivatedBy = entity.privateModeActivatedBy
      ..privateModeActivatedAt = entity.privateModeActivatedAt
      ..participantCount = entity.participantCount
      ..unreadCount = entity.unreadCount
      ..participants = entity.participants
          .map(ParticipantEntityCollection.fromEntity)
          .toList()
      ..organizationCode = entity.organizationCode
      ..schoolCode = entity.schoolCode
      ..privateModeStatesJson = entity.privateModeStates.isEmpty
          ? null
          : jsonEncode(
              entity.privateModeStates.map(
                (parentCode, s) => MapEntry(parentCode, {
                  'parentCode': s.parentCode,
                  'enabled': s.enabled,
                  'owner': s.owner,
                  'enabledAt': s.enabledAt.toIso8601String(),
                }),
              ),
            );
  }

  static Map<String, PrivateModeState> _decodePrivateModeStates(
    String? json,
  ) {
    if (json == null || json.isEmpty) return const {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((parentCode, value) {
      final v = value as Map<String, dynamic>;
      return MapEntry(
        parentCode,
        PrivateModeState(
          parentCode: v['parentCode'] as String,
          enabled: v['enabled'] as bool,
          owner: v['owner'] as String,
          enabledAt: DateTime.parse(v['enabledAt'] as String),
        ),
      );
    });
  }

  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      code: code,
      type: ConversationType.fromApiString(type),
      studentCode: studentCode,
      classroomCode: classroomCode,
      title: title,
      description: description,
      avatarUrl: avatarUrl,
      status: status,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessageAt: lastMessageAt,
      lastMessageBy: lastMessageBy,
      lastMessageSenderName: lastMessageSenderName,
      lastMessagePreview: lastMessagePreview,
      privateModeActive: privateModeActive,
      privateModeActivatedBy: privateModeActivatedBy,
      privateModeActivatedAt: privateModeActivatedAt,
      participantCount: participantCount,
      unreadCount: unreadCount,
      participants: participants?.map((e) => e.toEntity()).toList() ?? [],
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      privateModeStates: _decodePrivateModeStates(privateModeStatesJson),
    );
  }
}

@embedded
class ParticipantEntityCollection {
  late int id;
  late int conversationId;
  late String userCode;
  late String userName;

  /// Raw string; convert via [ParticipantRole.fromApiString].
  late String role;
  String? avatarUrl;
  late DateTime joinedAt;
  DateTime? leftAt;
  DateTime? lastReadAt;
  bool? muted;
  bool? notificationsEnabled;
  late DateTime createdAt;
  late DateTime updatedAt;

  ParticipantEntityCollection();

  factory ParticipantEntityCollection.fromEntity(ParticipantEntity entity) {
    return ParticipantEntityCollection()
      ..id = entity.id
      ..conversationId = entity.conversationId
      ..userCode = entity.userCode
      ..userName = entity.userName
      ..role = entity.role.toApiString()
      ..avatarUrl = entity.avatarUrl
      ..joinedAt = entity.joinedAt
      ..leftAt = entity.leftAt
      ..lastReadAt = entity.lastReadAt
      ..muted = entity.muted
      ..notificationsEnabled = entity.notificationsEnabled
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }

  ParticipantEntity toEntity() {
    return ParticipantEntity(
      id: id,
      conversationId: conversationId,
      userCode: userCode,
      userName: userName,
      role: ParticipantRole.fromApiString(role),
      avatarUrl: avatarUrl,
      joinedAt: joinedAt,
      leftAt: leftAt,
      lastReadAt: lastReadAt,
      muted: muted ?? false,
      notificationsEnabled: notificationsEnabled ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
