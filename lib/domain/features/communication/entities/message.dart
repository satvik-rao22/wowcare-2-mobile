import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String text;
  final bool isSentByMe;
  final DateTime time;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<RecipientStatus> deliveredTo;
  final List<RecipientStatus> readBy;
  final Map<String, String> reactions;
  final String? quotedMessageId;
  final List<ChatAttachment> attachments;
  final String? senderName;
  final List<String> receivers;

  const Message({
    required this.id,
    required this.text,
    required this.isSentByMe,
    required this.time,
    this.deliveredAt,
    this.readAt,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.reactions = const {},
    this.quotedMessageId,
    this.attachments = const [],
    this.senderName,
    this.receivers = const [],
  });

  bool get isDelivered => deliveredAt != null || deliveredTo.isNotEmpty;
  bool get isRead => readAt != null || readBy.isNotEmpty;
  int get readCount => readBy.length + (readAt != null ? 1 : 0);
  int get deliveredCount => deliveredTo.length + (deliveredAt != null ? 1 : 0);
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasMultiplePhotos => attachments.where((a) => a.isImage).length > 1;

  int get reactionCount => reactions.length;
  Map<String, int> get emojiCounts {
    final counts = <String, int>{};
    for (var emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  bool hasReacted(String currentUserId) => reactions.containsKey(currentUserId);
  String? getMyReaction(String currentUserId) => reactions[currentUserId];

  @override
  List<Object?> get props => [
        id,
        text,
        isSentByMe,
        time,
        deliveredAt,
        readAt,
        deliveredTo,
        readBy,
        reactions,
        quotedMessageId,
        attachments,
        senderName,
        receivers,
      ];
}

class RecipientStatus extends Equatable {
  final String name;
  final String? userId;
  final DateTime? timestamp;

  const RecipientStatus({
    required this.name,
    this.userId,
    this.timestamp,
  });

  @override
  List<Object?> get props => [name, userId, timestamp];
}

class ChatAttachment extends Equatable {
  final String name;
  final String type;
  final int sizeBytes;
  final String mimeType;
  final String remoteUrl;
  final String? localPath;

  const ChatAttachment({
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.mimeType,
    required this.remoteUrl,
    this.localPath,
  });

  bool get isImage => type == 'image' || mimeType.startsWith('image/');

  String? get displaySource => localPath ?? (remoteUrl.isNotEmpty ? remoteUrl : null);

  @override
  List<Object?> get props => [name, type, sizeBytes, mimeType, remoteUrl, localPath];
}
