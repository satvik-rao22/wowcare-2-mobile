import 'package:wowcare/domain/features/communication/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.text,
    required super.isSentByMe,
    required super.time,
    super.deliveredAt,
    super.readAt,
    super.deliveredTo,
    super.readBy,
    super.reactions,
    super.quotedMessageId,
    super.attachments,
    super.senderName,
    super.receivers,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isSentByMe: json['is_sent_by_me'] as bool,
      time: DateTime.parse(json['time'] as String),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      deliveredTo: (json['delivered_to'] as List<dynamic>?)
              ?.map((e) => RecipientStatusModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      readBy: (json['read_by'] as List<dynamic>?)
              ?.map((e) => RecipientStatusModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reactions: Map<String, String>.from(json['reactions'] ?? {}),
      quotedMessageId: json['quoted_message_id'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => ChatAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      senderName: json['sender_name'] as String?,
      receivers: (json['receivers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_sent_by_me': isSentByMe,
      'time': time.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'delivered_to': deliveredTo.map((e) => (e as RecipientStatusModel).toJson()).toList(),
      'read_by': readBy.map((e) => (e as RecipientStatusModel).toJson()).toList(),
      'reactions': reactions,
      'quoted_message_id': quotedMessageId,
      'attachments': attachments.map((e) => (e as ChatAttachmentModel).toJson()).toList(),
      'sender_name': senderName,
      'receivers': receivers,
    };
  }
}

class RecipientStatusModel extends RecipientStatus {
  const RecipientStatusModel({
    required super.name,
    super.userId,
    super.timestamp,
  });

  factory RecipientStatusModel.fromJson(Map<String, dynamic> json) {
    return RecipientStatusModel(
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_id': userId,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class ChatAttachmentModel extends ChatAttachment {
  const ChatAttachmentModel({
    required super.name,
    required super.type,
    required super.sizeBytes,
    required super.mimeType,
    required super.remoteUrl,
    super.localPath,
  });

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentModel(
      name: json['name'] as String,
      type: json['type'] as String,
      sizeBytes: json['size_bytes'] as int,
      mimeType: json['mime_type'] as String,
      remoteUrl: json['remote_url'] as String,
      localPath: json['local_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size_bytes': sizeBytes,
      'mime_type': mimeType,
      'remote_url': remoteUrl,
      'local_path': localPath,
    };
  }
}
