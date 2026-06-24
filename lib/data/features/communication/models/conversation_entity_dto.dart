import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

/// API response DTO for a conversation.
/// Maps directly from the JSON payload returned by the backend.
class ConversationEntityDto {
  const ConversationEntityDto({
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
    this.studentCode,
    this.classroomCode,
    this.lastMessageAt,
    this.lastMessageBy,
    this.lastMessageSenderName,
    this.privateModeStates = const [],
  });

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
  final int participantCount;
  final int unreadCount;
  final String lastMessagePreview;
  final List<ParticipantEntityDto> participants;
  final String? studentCode;
  final String? classroomCode;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final String? lastMessageSenderName;
  final List<PrivateModeStateDto> privateModeStates;

  factory ConversationEntityDto.fromJson(Map<String, dynamic> json) {
    return ConversationEntityDto(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'ROOM_CHAT',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      description: json['description'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: _parseDate(json['updatedAt']),
      updatedBy: json['updatedBy'] as String? ?? '',
      participantCount: json['participantCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ParticipantEntityDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studentCode: json['studentCode'] as String?,
      classroomCode: json['classroomCode'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      lastMessageBy: json['lastMessageBy'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      privateModeStates: (json['privateModeStates'] as List<dynamic>?)
              ?.map((e) => PrivateModeStateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'type': type,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'status': status,
        'description': description,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
        'participantCount': participantCount,
        'unreadCount': unreadCount,
        'lastMessagePreview': lastMessagePreview,
        'participants': participants.map((e) => e.toJson()).toList(),
        if (studentCode != null) 'studentCode': studentCode,
        if (classroomCode != null) 'classroomCode': classroomCode,
        if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
        if (lastMessageBy != null) 'lastMessageBy': lastMessageBy,
        if (lastMessageSenderName != null) 'lastMessageSenderName': lastMessageSenderName,
        'privateModeStates': privateModeStates.map((e) => e.toJson()).toList(),
      };

  /// Maps this DTO to the domain [ConversationEntity].
  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      code: code,
      title: title,
      type: ConversationType.fromApiString(type),
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
      unreadCount: unreadCount,
      lastMessagePreview: lastMessagePreview,
      participants: participants.map((e) => e.toEntity()).toList(),
      studentCode: studentCode,
      classroomCode: classroomCode,
      lastMessageAt: lastMessageAt,
      lastMessageBy: lastMessageBy,
      lastMessageSenderName: lastMessageSenderName,
      privateModeStates: {
        for (final s in privateModeStates) s.parentCode: s.toEntity()
      },
    );
  }

  static DateTime _parseDate(dynamic value) =>
      value != null ? DateTime.parse(value as String) : DateTime.now();
}

class ParticipantEntityDto {
  const ParticipantEntityDto({
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
  final String role;
  final String? avatarUrl;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? lastReadAt;
  final bool muted;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ParticipantEntityDto.fromJson(Map<String, dynamic> json) {
    return ParticipantEntityDto(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ?? 0,
      userCode: json['userCode'] as String? ?? '',
      userName: (json['displayName'] as String?)?.isNotEmpty == true
          ? json['displayName'] as String
          : (json['userName'] as String? ?? ''),
      role: (json['participantType'] as String?)?.isNotEmpty == true
          ? json['participantType'] as String
          : (json['role'] as String? ?? 'PARENT'),
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String? ?? DateTime.now().toIso8601String()),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt'] as String) : null,
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt'] as String) : null,
      muted: json['muted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'userCode': userCode,
        'userName': userName,
        'role': role,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'joinedAt': joinedAt.toIso8601String(),
        if (leftAt != null) 'leftAt': leftAt!.toIso8601String(),
        if (lastReadAt != null) 'lastReadAt': lastReadAt!.toIso8601String(),
        'muted': muted,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

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
      muted: muted,
      notificationsEnabled: notificationsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PrivateModeStateDto {
  const PrivateModeStateDto({
    required this.parentCode,
    required this.enabled,
    required this.owner,
    required this.enabledAt,
  });

  final String parentCode;
  final bool enabled;
  final String owner;
  final DateTime enabledAt;

  factory PrivateModeStateDto.fromJson(Map<String, dynamic> json) {
    return PrivateModeStateDto(
      parentCode: json['parentCode'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      owner: json['owner'] as String? ?? '',
      enabledAt: DateTime.parse(
        json['enabledAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'parentCode': parentCode,
        'enabled': enabled,
        'owner': owner,
        'enabledAt': enabledAt.toIso8601String(),
      };

  PrivateModeState toEntity() {
    return PrivateModeState(
      parentCode: parentCode,
      enabled: enabled,
      owner: owner,
      enabledAt: enabledAt,
    );
  }
}
