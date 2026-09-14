// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_entity_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationEntityDto _$ConversationEntityDtoFromJson(
        Map<String, dynamic> json) =>
    ConversationEntityDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      title: _readConvTitle(json, 'title') as String,
      type: json['type'] as String? ?? 'ROOM_CHAT',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      description: json['description'] as String? ?? '',
      avatarUrl: _readConvAvatar(json, 'avatarUrl') as String,
      createdAt: _parseDateOrNow(json['createdAt']),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: _parseDateOrNow(json['updatedAt']),
      updatedBy: json['updatedBy'] as String? ?? '',
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) =>
                  ParticipantEntityDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studentCode: json['studentCode'] as String?,
      studentStatus: json['studentStatus'] as String?,
      classroomCode: json['classroomCode'] as String?,
      lastMessageAt: _tryParseOrNull(json['lastMessageAt']),
      lastMessageBy: json['lastMessageBy'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      privateModeActive: json['privateModeActive'] as bool? ?? false,
      privateModeActivatedBy: json['privateModeActivatedBy'] as String?,
      privateModeActivatedAt: _tryParseOrNull(json['privateModeActivatedAt']),
      privateModeStates: (json['privateModeStates'] as List<dynamic>?)
              ?.map((e) =>
                  PrivateModeStateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ConversationEntityDtoToJson(
    ConversationEntityDto instance) {
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

  writeNotNull('studentCode', instance.studentCode);
  writeNotNull('studentStatus', instance.studentStatus);
  writeNotNull('classroomCode', instance.classroomCode);
  writeNotNull('lastMessageAt', instance.lastMessageAt?.toIso8601String());
  writeNotNull('lastMessageBy', instance.lastMessageBy);
  writeNotNull('lastMessageSenderName', instance.lastMessageSenderName);
  val['privateModeActive'] = instance.privateModeActive;
  writeNotNull('privateModeActivatedBy', instance.privateModeActivatedBy);
  writeNotNull('privateModeActivatedAt',
      instance.privateModeActivatedAt?.toIso8601String());
  val['privateModeStates'] =
      instance.privateModeStates.map((e) => e.toJson()).toList();
  return val;
}

ParticipantEntityDto _$ParticipantEntityDtoFromJson(
        Map<String, dynamic> json) =>
    ParticipantEntityDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      userCode: json['userCode'] as String? ?? '',
      userName: _readPartUserName(json, 'userName') as String,
      role: _readPartRole(json, 'role') as String,
      joinedAt: _parseDateOrNow(json['joinedAt']),
      muted: json['muted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: _parseDateOrNow(json['createdAt']),
      updatedAt: _parseDateOrNow(json['updatedAt']),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      avatarUrl: _readPartAvatar(json, 'avatarUrl') as String?,
      staffCode: json['staffCode'] as String?,
      guardianCode: json['guardianCode'] as String?,
      adminCode: json['adminCode'] as String?,
      organizationCode: json['organizationCode'] as String?,
      schoolCode: json['schoolCode'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      staffStatus: json['staffStatus'] as String?,
    );

Map<String, dynamic> _$ParticipantEntityDtoToJson(
    ParticipantEntityDto instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'conversationId': instance.conversationId,
    'userCode': instance.userCode,
    'userName': instance.userName,
    'role': instance.role,
    'avatarUrl': instance.avatarUrl,
    'joinedAt': instance.joinedAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('leftAt', instance.leftAt?.toIso8601String());
  writeNotNull('lastReadAt', instance.lastReadAt?.toIso8601String());
  val['muted'] = instance.muted;
  val['notificationsEnabled'] = instance.notificationsEnabled;
  val['createdAt'] = instance.createdAt.toIso8601String();
  val['updatedAt'] = instance.updatedAt.toIso8601String();
  writeNotNull('staffCode', instance.staffCode);
  writeNotNull('guardianCode', instance.guardianCode);
  writeNotNull('adminCode', instance.adminCode);
  writeNotNull('organizationCode', instance.organizationCode);
  writeNotNull('schoolCode', instance.schoolCode);
  val['unreadCount'] = instance.unreadCount;
  val['active'] = instance.active;
  writeNotNull('staffStatus', instance.staffStatus);
  return val;
}

PrivateModeStateDto _$PrivateModeStateDtoFromJson(Map<String, dynamic> json) =>
    PrivateModeStateDto(
      parentCode: json['parentCode'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      owner: json['owner'] as String? ?? '',
      enabledAt: _parseDateOrNow(json['enabledAt']),
    );

Map<String, dynamic> _$PrivateModeStateDtoToJson(
        PrivateModeStateDto instance) =>
    <String, dynamic>{
      'parentCode': instance.parentCode,
      'enabled': instance.enabled,
      'owner': instance.owner,
      'enabledAt': instance.enabledAt.toIso8601String(),
    };
