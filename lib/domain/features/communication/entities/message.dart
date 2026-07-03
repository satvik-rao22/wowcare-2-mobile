import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String code;
  final String text;
  final bool isSentByMe;
  final DateTime time;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final List<RecipientStatus> deliveredTo;
  final List<RecipientStatus> readBy;
  final Map<String, String> reactions;
  final String? quotedMessageId;
  final List<ChatAttachment> attachments;
  final String? senderName;
  final List<String> receivers;
  final String? senderUserCode;
  final bool isPrivate;
  final String? privateParentUserCode;
  final String? senderAvatarUrl;

  const Message({
    required this.id,
    required this.code,
    required this.text,
    required this.isSentByMe,
    required this.time,
    this.deliveredAt,
    this.readAt,
    this.editedAt,
    this.deletedAt,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.reactions = const {},
    this.quotedMessageId,
    this.attachments = const [],
    this.senderName,
    this.receivers = const [],
    this.senderUserCode,
    this.isPrivate = false,
    this.privateParentUserCode,
    this.senderAvatarUrl,
  });

  bool get isDelivered => deliveredAt != null || deliveredTo.isNotEmpty;
  bool get isRead => readAt != null || readBy.isNotEmpty;
  bool get isDeleted => deletedAt != null;
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

  Message copyWith({DateTime? deletedAt, List<ChatAttachment>? attachments, String? privateParentUserCode}) {
    return Message(
      id: id,
      code: code,
      text: text,
      isSentByMe: isSentByMe,
      time: time,
      deliveredAt: deliveredAt,
      readAt: readAt,
      editedAt: editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deliveredTo: deliveredTo,
      readBy: readBy,
      reactions: reactions,
      quotedMessageId: quotedMessageId,
      attachments: attachments ?? this.attachments,
      senderName: senderName,
      receivers: receivers,
      senderUserCode: senderUserCode,
      isPrivate: isPrivate,
      privateParentUserCode: privateParentUserCode ?? this.privateParentUserCode,
      senderAvatarUrl: senderAvatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        text,
        isSentByMe,
        time,
        deliveredAt,
        readAt,
        editedAt,
        deletedAt,
        deliveredTo,
        readBy,
        reactions,
        quotedMessageId,
        attachments,
        senderName,
        receivers,
        senderUserCode,
        isPrivate,
        privateParentUserCode,
        senderAvatarUrl,
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

  /// Asset code returned by the upload-session pipeline once this attachment
  /// has been uploaded to the document service. Identifies the underlying
  /// file but is not itself a valid `sendMessage` reference — see
  /// [attachmentId].
  final String? code;

  /// Messaging-service attachment id returned by registering [code] against
  /// the conversation. This — not [code] — is what `sendMessage` expects in
  /// `attachmentIds`; null until registration completes.
  final int? attachmentId;

  const ChatAttachment({
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.mimeType,
    required this.remoteUrl,
    this.localPath,
    this.code,
    this.attachmentId,
  });

  bool get isImage => type == 'image' || mimeType.startsWith('image/');

  String? get displaySource => localPath ?? (remoteUrl.isNotEmpty ? remoteUrl : null);

  bool get isUploaded => (code ?? '').isNotEmpty && attachmentId != null;

  ChatAttachment copyWith({String? remoteUrl, String? code, int? attachmentId}) {
    return ChatAttachment(
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath,
      code: code ?? this.code,
      attachmentId: attachmentId ?? this.attachmentId,
    );
  }

  @override
  List<Object?> get props =>
      [name, type, sizeBytes, mimeType, remoteUrl, localPath, code, attachmentId];
}
