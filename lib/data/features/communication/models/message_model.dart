import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

class MessageModel extends Message {
  final String? conversationCode;
  final String senderUserCode;

  const MessageModel({
    required super.id,
    required super.code,
    required super.text,
    required super.isSentByMe,
    required super.time,
    this.conversationCode,
    required this.senderUserCode,
    super.deliveredAt,
    super.readAt,
    super.editedAt,
    super.deletedAt,
    super.deliveredTo,
    super.readBy,
    super.reactions,
    super.quotedMessageId,
    super.attachments,
    super.senderName,
    super.receivers,
    super.isPrivate = false,
  }) : super(senderUserCode: senderUserCode);

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderCode = (json['senderUserCode'] as String? ?? json['senderCode'] as String? ?? '').trim();
    final normalizedUserId = currentUserId?.trim();
    final isMine = normalizedUserId != null &&
        normalizedUserId.isNotEmpty &&
        senderCode.isNotEmpty &&
        senderCode == normalizedUserId;

    AppLogger.d(
      '[CHAT OWNERSHIP] fromJson\n'
      '  messageId      = ${json['id']}\n'
      '  code           = ${json['code']}\n'
      '  senderUserCode = $senderCode\n'
      '  currentUserId  = $normalizedUserId\n'
      '  isMine         = $isMine',
    );

    return MessageModel(
      id: (json['id'] ?? '').toString(),
      code: json['code'] as String? ?? '',
      conversationCode: json['conversationCode'] as String? ?? json['conversation_code'] as String?,
      senderUserCode: senderCode,
      text: json['content'] as String? ?? '',
      isSentByMe: isMine,
      time: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      deliveredAt: json['status'] == 'DELIVERED' || json['status'] == 'READ'
          ? DateTime.now()
          : null,
      readAt: json['status'] == 'READ' ? DateTime.now() : null,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      deliveredTo: const [],
      readBy: const [],
      reactions: {
        for (var r in (json['reactions'] as List<dynamic>?) ?? [])
          if (r is Map<String, dynamic> && r['userCode'] != null && r['emoji'] != null)
            r['userCode'].toString(): r['emoji'].toString()
      },
      quotedMessageId: (json['replyToMessageId'] ?? '').toString().isEmpty
          ? null
          : json['replyToMessageId'].toString(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => ChatAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      senderName: (json['senderDisplayName'] as String?)?.isNotEmpty == true
          ? json['senderDisplayName'] as String
          : json['senderName'] as String?,
      receivers: const [],
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'conversationCode': conversationCode,
      'senderUserCode': senderUserCode,
      'content': text,
      'time': time.toIso8601String(),
      'replyToMessageId': quotedMessageId,
      'attachments': attachments.map((e) => (e as ChatAttachmentModel).toJson()).toList(),
      'senderName': senderName,
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
      name: json['name'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String?,
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
    super.code,
    super.attachmentId,
  });

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['attachmentId'] ?? json['id'];
    // The messaging service's own attachment row (returned inline with each
    // message — see GET .../messages/conversation/{code}) uses a different
    // shape than the local upload-pipeline model below: `originalFilename`,
    // `attachmentType`, `fileSize`, `assetCode`, and a `fileUrl`/
    // `thumbnailUrl` that is null until the document service finishes
    // resolving it (see AttachmentUrlResolver for that resolution step).
    return ChatAttachmentModel(
      name: (json['name'] ?? json['originalFilename']) as String? ?? '',
      type: (json['type'] ?? json['attachmentType']) as String? ?? '',
      sizeBytes:
          (json['size_bytes'] ?? json['sizeBytes'] ?? json['fileSize']) as int? ?? 0,
      mimeType: (json['mime_type'] ?? json['mimeType']) as String? ?? '',
      remoteUrl: (json['remote_url'] ??
              json['remoteUrl'] ??
              json['fileUrl'] ??
              json['thumbnailUrl']) as String? ??
          '',
      localPath: (json['local_path'] ?? json['localPath']) as String?,
      code: (json['code'] ?? json['assetCode']) as String?,
      attachmentId: rawId is int ? rawId : int.tryParse('$rawId'),
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
      'code': code,
      'attachmentId': attachmentId,
    };
  }
}
