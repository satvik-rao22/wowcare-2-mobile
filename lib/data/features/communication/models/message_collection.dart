import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

part 'message_collection.g.dart';

@collection
class MessageCollection {
  Id get isarId => fastHash(code.isNotEmpty ? code : id);

  late String id;
  late String code;
  @Index()
  late String threadId;
  late String text;
  bool? isSentByMe;
  String? senderUserCode;
  late DateTime time;
  DateTime? deliveredAt;
  DateTime? readAt;
  DateTime? editedAt;
  DateTime? deletedAt;
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
      ..code = message.code
      ..threadId = threadId
      ..text = message.text
      ..isSentByMe = message.isSentByMe
      ..senderUserCode = message.senderUserCode
      ..time = message.time
      ..deliveredAt = message.deliveredAt
      ..readAt = message.readAt
      ..editedAt = message.editedAt
      ..deletedAt = message.deletedAt
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

  /// Converts to a domain [Message].
  ///
  /// When [currentUserId] is supplied the [isSentByMe] flag is re-derived
  /// from [senderUserCode] at read-time, which is the authoritative source.
  /// This prevents stale/null Isar booleans from flipping the bubble style.
  Message toEntity({String? currentUserId}) {
    final normalizedUserId = currentUserId?.trim();
    final normalizedSenderCode = senderUserCode?.trim();
    final resolvedIsSentByMe =
        (normalizedUserId != null &&
            normalizedUserId.isNotEmpty &&
            normalizedSenderCode != null &&
            normalizedSenderCode.isNotEmpty)
        ? normalizedSenderCode == normalizedUserId
        : (isSentByMe ?? false);

    return Message(
      id: id,
      code: code,
      text: text,
      isSentByMe: resolvedIsSentByMe,
      senderUserCode: normalizedSenderCode,
      time: time,
      deliveredAt: deliveredAt,
      readAt: readAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
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

@embedded
class MessageReactionCollection {
  late String userId;
  late String emoji;
}

@embedded
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

@embedded
class ChatAttachmentCollection {
  late String name;
  late String type;
  late int sizeBytes;
  late String mimeType;
  late String remoteUrl;
  String? localPath;
  String? code;
  int? attachmentId;

  ChatAttachmentCollection();

  factory ChatAttachmentCollection.fromEntity(ChatAttachment attachment) {
    return ChatAttachmentCollection()
      ..name = attachment.name
      ..type = attachment.type
      ..sizeBytes = attachment.sizeBytes
      ..mimeType = attachment.mimeType
      ..remoteUrl = attachment.remoteUrl
      ..localPath = attachment.localPath
      ..code = attachment.code
      ..attachmentId = attachment.attachmentId;
  }

  ChatAttachment toEntity() {
    return ChatAttachment(
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      remoteUrl: remoteUrl,
      localPath: localPath,
      code: code,
      attachmentId: attachmentId,
    );
  }
}
