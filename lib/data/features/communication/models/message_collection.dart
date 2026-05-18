import 'package:isar/isar.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

part 'message_collection.g.dart';

@collection
class MessageCollection {
  Id isarId = Isar.autoIncrement;

  late String id;

  @Index(type: IndexType.hash)
  late String threadId;

  late String text;
  late bool isSentByMe;
  late DateTime time;
  DateTime? deliveredAt;
  DateTime? readAt;
  String? quotedMessageId;
  String? senderName;
  List<String>? receivers;

  List<RecipientStatusCollection>? deliveredTo;
  List<RecipientStatusCollection>? readBy;
  List<ChatAttachmentCollection>? attachments;
  List<MessageReactionCollection>? reactions;

  MessageCollection();

  factory MessageCollection.fromEntity(Message message, String threadId) {
    return MessageCollection()
      ..id = message.id
      ..threadId = threadId
      ..text = message.text
      ..isSentByMe = message.isSentByMe
      ..time = message.time
      ..deliveredAt = message.deliveredAt
      ..readAt = message.readAt
      ..quotedMessageId = message.quotedMessageId
      ..senderName = message.senderName
      ..receivers = message.receivers
      ..deliveredTo = message.deliveredTo
          .map((e) => RecipientStatusCollection.fromEntity(e))
          .toList()
      ..readBy = message.readBy
          .map((e) => RecipientStatusCollection.fromEntity(e))
          .toList()
      ..attachments = message.attachments
          .map((e) => ChatAttachmentCollection.fromEntity(e))
          .toList()
      ..reactions = message.reactions.entries
          .map(
            (e) => MessageReactionCollection()
              ..userId = e.key
              ..emoji = e.value,
          )
          .toList();
  }

  Message toEntity() {
    return Message(
      id: id,
      text: text,
      isSentByMe: isSentByMe,
      time: time,
      deliveredAt: deliveredAt,
      readAt: readAt,
      quotedMessageId: quotedMessageId,
      senderName: senderName,
      receivers: receivers ?? [],
      deliveredTo: deliveredTo?.map((e) => e.toEntity()).toList() ?? [],
      readBy: readBy?.map((e) => e.toEntity()).toList() ?? [],
      attachments: attachments?.map((e) => e.toEntity()).toList() ?? [],
      reactions: {for (var r in reactions ?? []) r.userId: r.emoji},
    );
  }
}

class MessageReactionCollection {
  late String userId;
  late String emoji;
}

class RecipientStatusCollection {
  late String name;
  String? userId;
  DateTime? timestamp;

  RecipientStatusCollection();

  factory RecipientStatusCollection.fromEntity(RecipientStatus status) {
    return RecipientStatusCollection()
      ..name = status.name
      ..userId = status.userId
      ..timestamp = status.timestamp;
  }

  RecipientStatus toEntity() {
    return RecipientStatus(name: name, userId: userId, timestamp: timestamp);
  }
}

class ChatAttachmentCollection {
  late String name;
  late String type;
  late int sizeBytes;
  late String mimeType;
  late String remoteUrl;
  String? localPath;

  ChatAttachmentCollection();

  factory ChatAttachmentCollection.fromEntity(ChatAttachment attachment) {
    return ChatAttachmentCollection()
      ..name = attachment.name
      ..type = attachment.type
      ..sizeBytes = attachment.sizeBytes
      ..mimeType = attachment.mimeType
      ..remoteUrl = attachment.remoteUrl
      ..localPath = attachment.localPath;
  }

  ChatAttachment toEntity() {
    return ChatAttachment(
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      remoteUrl: remoteUrl,
      localPath: localPath,
    );
  }
}
