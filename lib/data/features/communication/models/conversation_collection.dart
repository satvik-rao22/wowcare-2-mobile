import 'package:isar/isar.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';

part 'conversation_collection.g.dart';

@collection
class ConversationCollection {
  Id get isarId => id;

  late int id;
  late String code;
  late String title;
  late String type;
  late String organizationCode;
  late String schoolCode;
  late String status;
  late String description;
  late String avatarUrl;
  late DateTime createdAt;
  late String createdBy;
  late DateTime updatedAt;
  late String updatedBy;
  DateTime? lastMessageAt;
  String? lastMessageBy;
  String? lastMessageSenderName;
  bool privateModeActive = false;
  String? privateModeActivatedBy;
  DateTime? privateModeActivatedAt;
  late int participantCount;
  late int unreadCount;
  late String lastMessagePreview;
  List<ConversationParticipantCollection>? participants;

  ConversationCollection();

  factory ConversationCollection.fromEntity(Conversation entity) {
    return ConversationCollection()
      ..id = entity.id
      ..code = entity.code
      ..title = entity.title
      ..type = entity.type
      ..organizationCode = entity.organizationCode
      ..schoolCode = entity.schoolCode
      ..status = entity.status
      ..description = entity.description
      ..avatarUrl = entity.avatarUrl
      ..createdAt = entity.createdAt
      ..createdBy = entity.createdBy
      ..updatedAt = entity.updatedAt
      ..updatedBy = entity.updatedBy
      ..lastMessageAt = entity.lastMessageAt
      ..lastMessageBy = entity.lastMessageBy
      ..lastMessageSenderName = entity.lastMessageSenderName
      ..privateModeActive = entity.privateModeActive
      ..privateModeActivatedBy = entity.privateModeActivatedBy
      ..privateModeActivatedAt = entity.privateModeActivatedAt
      ..participantCount = entity.participantCount
      ..unreadCount = entity.unreadCount
      ..lastMessagePreview = entity.lastMessagePreview
      ..participants = entity.participants
          .map((e) => ConversationParticipantCollection.fromEntity(e))
          .toList();
  }

  Conversation toEntity() {
    return Conversation(
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
      participants: participants?.map((e) => e.toEntity()).toList() ?? [],
    );
  }
}

@embedded
class ConversationParticipantCollection {
  late int id;
  late int conversationId;
  late String userCode;
  late String userName;
  late String role;
  late DateTime joinedAt;
  DateTime? leftAt;
  DateTime? lastReadAt;
  bool? muted;
  bool? notificationsEnabled;
  late DateTime createdAt;
  late DateTime updatedAt;

  ConversationParticipantCollection();

  factory ConversationParticipantCollection.fromEntity(
    ConversationParticipant entity,
  ) {
    return ConversationParticipantCollection()
      ..id = entity.id
      ..conversationId = entity.conversationId
      ..userCode = entity.userCode
      ..userName = entity.userName
      ..role = entity.role
      ..joinedAt = entity.joinedAt
      ..leftAt = entity.leftAt
      ..lastReadAt = entity.lastReadAt
      ..muted = entity.muted
      ..notificationsEnabled = entity.notificationsEnabled
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }

  ConversationParticipant toEntity() {
    return ConversationParticipant(
      id: id,
      conversationId: conversationId,
      userCode: userCode,
      userName: userName,
      role: role,
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
