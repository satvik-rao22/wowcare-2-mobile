import 'package:equatable/equatable.dart';

import 'reaction_entry.dart';

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
  final List<ReactionEntry> reactions;
  final String? quotedMessageId;
  final List<ChatAttachment> attachments;
  final String? senderName;
  final List<String> receivers;
  final String? senderUserCode;
  final bool isPrivate;
  final String? privateParentUserCode;

  /// True when this message failed to send (upload or API error) — the
  /// bubble should show a retry affordance.
  final bool isFailed;

  /// True while this message is still in flight — attachments uploading (or
  /// awaiting the document service's READY status) and/or the create-message
  /// API call itself not yet confirmed. Drives the bubble's tick row: a
  /// small spinner instead of the sent/delivered/read tick, so an in-flight
  /// send never looks identical to a confirmed one.
  final bool isSending;

  /// True when this message sent successfully but at least one attachment
  /// is still waiting on the document service to finish processing it into
  /// a real URL — the bubble shows the local preview with a "Processing"
  /// badge instead of a broken/blank image.
  final bool hasProcessingAttachments;

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
    this.reactions = const [],
    this.quotedMessageId,
    this.attachments = const [],
    this.senderName,
    this.receivers = const [],
    this.senderUserCode,
    this.isPrivate = false,
    this.privateParentUserCode,
    this.isFailed = false,
    this.hasProcessingAttachments = false,
    this.isSending = false,
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
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return counts;
  }

  /// True if [userCode] has placed [emoji] on this message (case-insensitive,
  /// trimmed userCode match; exact emoji match).
  bool userHasReaction(String userCode, String emoji) =>
      reactions.any((r) => r.matchesUser(userCode) && r.emoji == emoji);

  /// The emojis [userCode] has reacted with (case-insensitive, trimmed match).
  List<String> reactionsOf(String userCode) => reactions
      .where((r) => r.matchesUser(userCode))
      .map((r) => r.emoji)
      .toList();

  bool hasReacted(String currentUserId) =>
      reactions.any((r) => r.matchesUser(currentUserId));

  /// The first emoji [currentUserId] reacted with, if any. Prefer
  /// [reactionsOf] now that a user may hold multiple reactions.
  String? getMyReaction(String currentUserId) {
    final mine = reactionsOf(currentUserId);
    return mine.isEmpty ? null : mine.first;
  }

  Message copyWith({
    DateTime? deletedAt,
    List<ChatAttachment>? attachments,
    String? privateParentUserCode,
    List<ReactionEntry>? reactions,
    bool? isFailed,
    bool? hasProcessingAttachments,
    bool? isSending,
  }) {
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
      reactions: reactions ?? this.reactions,
      quotedMessageId: quotedMessageId,
      attachments: attachments ?? this.attachments,
      senderName: senderName,
      receivers: receivers,
      senderUserCode: senderUserCode,
      isPrivate: isPrivate,
      privateParentUserCode: privateParentUserCode ?? this.privateParentUserCode,
      isFailed: isFailed ?? this.isFailed,
      hasProcessingAttachments:
          hasProcessingAttachments ?? this.hasProcessingAttachments,
      isSending: isSending ?? this.isSending,
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
        isFailed,
        hasProcessingAttachments,
        isSending,
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

  bool get isVideo => type == 'video' || mimeType.startsWith('video/');

  String? get displaySource => localPath ?? (remoteUrl.isNotEmpty ? remoteUrl : null);

  bool get isUploaded => (code ?? '').isNotEmpty && attachmentId != null;

  ChatAttachment copyWith({
    String? remoteUrl,
    String? code,
    int? attachmentId,
    String? localPath,
  }) {
    return ChatAttachment(
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
      code: code ?? this.code,
      attachmentId: attachmentId ?? this.attachmentId,
    );
  }

  @override
  List<Object?> get props =>
      [name, type, sizeBytes, mimeType, remoteUrl, localPath, code, attachmentId];
}
