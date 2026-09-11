// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) =>
    ConversationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      title: _readConversationTitle(json, 'title') as String,
      type: json['type'] as String? ?? 'DIRECT',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      description: json['description'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      createdAt: _dateOrNow(json['createdAt']),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: _dateOrNow(json['updatedAt']),
      updatedBy: json['updatedBy'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessageBy: json['lastMessageBy'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      privateModeActive: json['privateModeActive'] as bool? ?? false,
      privateModeActivatedBy: json['privateModeActivatedBy'] as String?,
      privateModeActivatedAt:
          _dateTryParseOrNull(json['privateModeActivatedAt']),
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ConversationParticipantModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      studentStatus: json['studentStatus'] as String?,
      classroomCode: json['classroomCode'] as String?,
    );

Map<String, dynamic> _$ConversationModelToJson(ConversationModel instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'code': instance.code,
    'title': instance.title,
    'type': instance.type,
    'organizationCode': instance.organizationCode,
    'schoolCode': instance.schoolCode,
    'status': instance.status,
    'description': instance.description,
    'avatarUrl': instance.avatarUrl,
    'createdAt': instance.createdAt.toIso8601String(),
    'createdBy': instance.createdBy,
    'updatedAt': instance.updatedAt.toIso8601String(),
    'updatedBy': instance.updatedBy,
    'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
    'lastMessageBy': instance.lastMessageBy,
    'lastMessageSenderName': instance.lastMessageSenderName,
    'privateModeActive': instance.privateModeActive,
    'privateModeActivatedBy': instance.privateModeActivatedBy,
    'privateModeActivatedAt':
        instance.privateModeActivatedAt?.toIso8601String(),
    'participantCount': instance.participantCount,
    'unreadCount': instance.unreadCount,
    'lastMessagePreview': instance.lastMessagePreview,
    'participants': instance.participants.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('studentStatus', instance.studentStatus);
  writeNotNull('classroomCode', instance.classroomCode);
  return val;
}

ConversationParticipantModel _$ConversationParticipantModelFromJson(
        Map<String, dynamic> json) =>
    ConversationParticipantModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      userCode: json['userCode'] as String? ?? '',
      userName: _readParticipantUserName(json, 'userName') as String,
      role: _readParticipantRole(json, 'role') as String,
      joinedAt: _dateOrNow(json['joinedAt']),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      muted: json['muted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: _dateOrNow(json['createdAt']),
      updatedAt: _dateOrNow(json['updatedAt']),
      privateModeEnabled: json['privateModeEnabled'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      staffStatus: json['staffStatus'] as String?,
      avatarUrl: _readParticipantAvatar(json, 'avatarUrl') as String?,
      staffCode: json['staffCode'] as String?,
    );

Map<String, dynamic> _$ConversationParticipantModelToJson(
    ConversationParticipantModel instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'conversationId': instance.conversationId,
    'userCode': instance.userCode,
    'userName': instance.userName,
    'role': instance.role,
    'joinedAt': instance.joinedAt.toIso8601String(),
    'leftAt': instance.leftAt?.toIso8601String(),
    'lastReadAt': instance.lastReadAt?.toIso8601String(),
    'muted': instance.muted,
    'notificationsEnabled': instance.notificationsEnabled,
    'createdAt': instance.createdAt.toIso8601String(),
    'updatedAt': instance.updatedAt.toIso8601String(),
    'privateModeEnabled': instance.privateModeEnabled,
    'unreadCount': instance.unreadCount,
    'active': instance.active,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('staffStatus', instance.staffStatus);
  writeNotNull('avatarUrl', instance.avatarUrl);
  writeNotNull('staffCode', instance.staffCode);
  return val;
}
