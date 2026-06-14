import '../../../../domain/features/communication/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.code,
    required super.title,
    required super.type,
    required super.organizationCode,
    required super.schoolCode,
    required super.status,
    required super.description,
    required super.avatarUrl,
    required super.createdAt,
    required super.createdBy,
    required super.updatedAt,
    required super.updatedBy,
    super.lastMessageAt,
    super.lastMessageBy,
    required super.participantCount,
    required super.unreadCount,
    required super.lastMessagePreview,
    required super.participants,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'DIRECT',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      description: json['description'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      updatedBy: json['updatedBy'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      lastMessageBy: json['lastMessageBy'] as String?,
      participantCount: json['participantCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) =>
                  ConversationParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessageBy': lastMessageBy,
      'participantCount': participantCount,
      'unreadCount': unreadCount,
      'lastMessagePreview': lastMessagePreview,
      'participants': participants
          .map((e) => (e as ConversationParticipantModel).toJson())
          .toList(),
    };
  }
}

class ConversationParticipantModel extends ConversationParticipant {
  const ConversationParticipantModel({
    required super.id,
    required super.conversationId,
    required super.userCode,
    required super.userName,
    required super.role,
    required super.joinedAt,
    super.leftAt,
    super.lastReadAt,
    required super.muted,
    required super.notificationsEnabled,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) {
    return ConversationParticipantModel(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ?? 0,
      userCode: json['userCode'] as String? ?? '',
      // New API uses 'displayName'; old API used 'userName'. Accept both.
      userName: (json['displayName'] as String?)?.isNotEmpty == true
          ? json['displayName'] as String
          : json['userName'] as String? ?? '',
      // New API uses 'participantType'; old API used 'role'. Accept both.
      role: json['participantType'] as String? ??
          json['role'] as String? ??
          'STAFF',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt'] as String) : null,
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt'] as String) : null,
      muted: json['muted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'userCode': userCode,
      'userName': userName,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'muted': muted,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
