import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/reaction_entry.dart';
import 'package:wowcare/core/util/app_time.dart';

/// API response DTO for a message.
class MessageEntityDto {
  const MessageEntityDto({
    required this.id,
    required this.code,
    required this.conversationCode,
    required this.senderCode,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.messageType,
    required this.status,
    required this.sentAt,
    required this.organizationCode,
    required this.schoolCode,
    this.senderAvatarUrl,
    this.isPrivate = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.deletedPlaceholder,
    this.editedAt,
    this.deletedAt,
    this.attachments = const [],
    this.reactions = const [],
    this.readReceipts = const [],
    this.threadParentCode,
    this.threadParentSenderCode,
    this.threadParentSenderName,
    this.threadParentText,
    this.privateParentUserCode,
  });

  final String id;
  final String code;
  final String conversationCode;
  final String senderCode;
  final String senderName;
  final String senderRole;
  final String? senderAvatarUrl;
  final String text;
  final String messageType;
  final String status;
  final bool isPrivate;
  final bool isEdited;
  final bool isDeleted;
  final String? deletedPlaceholder;
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final List<AttachmentEntityDto> attachments;
  final List<ReactionDto> reactions;
  final List<ReadReceiptEntityDto> readReceipts;
  final String? threadParentCode;
  final String? threadParentSenderCode;
  final String? threadParentSenderName;
  final String? threadParentText;
  // Backend field name confirmed live via MessageModel.fromJson (REST) and
  // MessageFirestoreItem.fromFirestore (realtime) — both already parse this
  // exact key successfully from production responses/documents.
  final String? privateParentUserCode;
  final String organizationCode;
  final String schoolCode;

  factory MessageEntityDto.fromJson(Map<String, dynamic> json) {
    // Backend uses 'content' for message text, 'createdAt' for sent time,
    // 'replyToMessageId' for thread parent, and accepts both 'senderCode'
    // and 'senderUserCode' — confirmed from existing MessageModel.fromJson.
    final senderCode =
        (json['senderUserCode'] as String? ??
                json['senderCode'] as String? ??
                '')
            .trim();

    return MessageEntityDto(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      conversationCode:
          json['conversationCode'] as String? ??
          json['conversation_code'] as String? ??
          '',
      senderCode: senderCode,
      // Backend sends 'senderDisplayName' on the messages endpoint; 'senderName'
      // is kept as a fallback for any older/alternate response shapes.
      senderName:
          (json['senderDisplayName'] as String? ??
                  json['senderName'] as String? ??
                  '')
              .trim(),
      senderRole: json['senderRole'] as String? ?? 'PARENT',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      // Backend field is 'content', not 'text'
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      messageType:
          json['messageType'] as String? ?? json['type'] as String? ?? 'TEXT',
      status: json['status'] as String? ?? 'SENT',
      // ppc-presence is authoritative (backend invariant isPrivate = ppc != null)
      // and takes precedence over the API's `isPrivate`/`private` booleans, which
      // come back false even when ppc is set — see message_model.dart.
      isPrivate:
          ((json['privateParentUserCode'] as String?)?.trim().isNotEmpty ??
              false) ||
          (json['isPrivate'] as bool? ?? false) ||
          (json['private'] as bool? ?? false),
      isEdited: json['isEdited'] as bool? ?? json['edited'] as bool? ?? false,
      isDeleted:
          json['isDeleted'] as bool? ?? json['deleted'] as bool? ?? false,
      deletedPlaceholder: json['deletedPlaceholder'] as String?,
      // Backend field is 'createdAt', not 'sentAt'
      sentAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : AppTime.nowUtc(),
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => AttachmentEntityDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((e) => ReactionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      // The list endpoint's actual key is `receipts`, not `readReceipts` —
      // confirmed against a live payload (GET .../messages/conversation/
      // {code}). This was silently parsing to an empty list every time,
      // regardless of what the backend sent, which is why ticks/message-
      // info never reflected per-recipient delivered/read state — only
      // whatever the message's own coarse top-level `status` happened to
      // say. `readReceipts` is kept as a fallback in case some other
      // response shape genuinely uses that key.
      readReceipts:
          ((json['receipts'] ?? json['readReceipts']) as List<dynamic>?)
              ?.map(
                (e) => ReadReceiptEntityDto.fromJson(
                  e as Map<String, dynamic>,
                  fallbackMessageCode: json['code'] as String? ?? '',
                ),
              )
              .toList() ??
          [],
      // The REST DTO carries the quoted-message context under `parent*` keys
      // (parentMessageCode is the quoted message's CODE, which matches how the
      // Firestore doc and the loaded message list identify it). Fall back to the
      // numeric `replyToMessageId` / legacy `threadParent*` for older payloads.
      threadParentCode:
          (json['parentMessageCode'] as String?) ??
          (json['replyToMessageId']?.toString().isNotEmpty == true
              ? json['replyToMessageId'].toString()
              : json['threadParentCode'] as String?),
      threadParentSenderCode:
          (json['parentSenderCode'] ?? json['threadParentSenderCode'])
              as String?,
      threadParentSenderName:
          (json['parentSenderName'] ?? json['threadParentSenderName'])
              as String?,
      threadParentText:
          (json['parentText'] ?? json['threadParentText']) as String?,
      privateParentUserCode: json['privateParentUserCode'] as String?,
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'conversationCode': conversationCode,
    'senderCode': senderCode,
    'senderName': senderName,
    'senderRole': senderRole,
    if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
    'content': text, // Backend uses 'content', not 'text'
    'type': messageType, // Backend uses 'type' for send, not 'messageType'
    'status': status,
    'isPrivate': isPrivate,
    'isEdited': isEdited,
    'isDeleted': isDeleted,
    if (deletedPlaceholder != null) 'deletedPlaceholder': deletedPlaceholder,
    'createdAt': sentAt.toIso8601String(), // Backend uses 'createdAt'
    if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'reactions': reactions.map((e) => e.toJson()).toList(),
    'readReceipts': readReceipts.map((e) => e.toJson()).toList(),
    // Backend uses 'replyToMessageId', not 'threadParentCode'
    if (threadParentCode != null) 'replyToMessageId': threadParentCode,
    if (threadParentSenderCode != null)
      'threadParentSenderCode': threadParentSenderCode,
    if (threadParentSenderName != null)
      'threadParentSenderName': threadParentSenderName,
    if (threadParentText != null) 'threadParentText': threadParentText,
    if (privateParentUserCode != null)
      'privateParentUserCode': privateParentUserCode,
  };

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      code: code,
      conversationCode: conversationCode,
      senderCode: senderCode,
      senderName: senderName,
      senderRole: ParticipantRole.fromApiString(senderRole),
      senderAvatarUrl: senderAvatarUrl,
      text: text,
      messageType: MessageType.fromApiString(messageType),
      status: MessageStatus.fromApiString(status),
      isPrivate: isPrivate,
      isEdited: isEdited,
      isDeleted: isDeleted,
      deletedPlaceholder: deletedPlaceholder,
      sentAt: sentAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      attachments: attachments.map((e) => e.toEntity()).toList(),
      reactions: reactions
          .map(
            (r) => ReactionEntry(
              userCode: r.userCode,
              emoji: r.emoji,
              role: r.role,
              userName: r.userName.isNotEmpty ? r.userName : null,
            ),
          )
          .toList(),
      readReceipts: readReceipts.map((e) => e.toEntity()).toList(),
      threadParentCode: threadParentCode,
      threadParentSenderCode: threadParentSenderCode,
      threadParentSenderName: threadParentSenderName,
      threadParentText: threadParentText,
      privateParentUserCode: privateParentUserCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}

class AttachmentEntityDto {
  const AttachmentEntityDto({
    required this.code,
    required this.messageCode,
    required this.conversationCode,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.uploadedBy,
    required this.uploadedAt,
    this.thumbnailUrl,
    this.attachmentId,
  });

  final String code;
  final String messageCode;
  final String conversationCode;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int fileSizeBytes;
  final String? thumbnailUrl;
  final String uploadedBy;
  final DateTime uploadedAt;

  /// Messaging-service attachment id — same backend field legacy's
  /// `ChatAttachmentModel.fromJson` reads as `attachmentId`/`id`, required by
  /// `DELETE /messages/attachments/{id}`. Was previously dropped here even
  /// though the backend already returns it on every message response.
  final int? attachmentId;

  factory AttachmentEntityDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['attachmentId'] ?? json['id'];
    return AttachmentEntityDto(
      code: json['code'] as String? ?? '',
      messageCode: json['messageCode'] as String? ?? '',
      conversationCode: json['conversationCode'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploadedAt: DateTime.parse(
        json['uploadedAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
      ),
      attachmentId: rawId is int ? rawId : int.tryParse('$rawId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'messageCode': messageCode,
    'conversationCode': conversationCode,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'mimeType': mimeType,
    'fileSizeBytes': fileSizeBytes,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    'uploadedBy': uploadedBy,
    'uploadedAt': uploadedAt.toIso8601String(),
    if (attachmentId != null) 'attachmentId': attachmentId,
  };

  AttachmentEntity toEntity() {
    return AttachmentEntity(
      code: code,
      messageCode: messageCode,
      conversationCode: conversationCode,
      fileName: fileName,
      fileUrl: fileUrl,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      attachmentType: AttachmentType.fromMimeType(mimeType),
      thumbnailUrl: thumbnailUrl,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      attachmentId: attachmentId,
    );
  }
}

class ReactionDto {
  const ReactionDto({
    required this.messageCode,
    required this.userCode,
    required this.userName,
    required this.emoji,
    required this.createdAt,
    this.role,
  });

  final String messageCode;
  final String userCode;
  final String userName;
  final String emoji;
  final DateTime createdAt;

  /// Raw backend role string (e.g. "STAFF") the reactor was acting AS —
  /// confirmed present on the reaction row as `role`/`userRole`.
  final String? role;

  factory ReactionDto.fromJson(Map<String, dynamic> json) {
    return ReactionDto(
      messageCode: json['messageCode'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
      ),
      role: (json['role'] ?? json['userRole'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'messageCode': messageCode,
    'userCode': userCode,
    'userName': userName,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
    'role': role,
  };
}

class ReadReceiptEntityDto {
  const ReadReceiptEntityDto({
    required this.messageCode,
    required this.userCode,
    required this.userName,
    this.deliveredAt,
    this.readAt,
    this.role,
  });

  final String messageCode;
  final String userCode;
  final String userName;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  /// Raw backend role string (e.g. "STAFF") the recipient was acting AS —
  /// confirmed present on the receipt row as `role`/`userRole`.
  final String? role;

  factory ReadReceiptEntityDto.fromJson(
    Map<String, dynamic> json, {
    String fallbackMessageCode = '',
  }) {
    return ReadReceiptEntityDto(
      // The per-receipt payload only carries the numeric `messageId`
      // (matching its parent message's own `id`, not `code`) — there's no
      // `messageCode` field on the receipt itself, so fall back to the
      // parent message's code (already known at the call site).
      messageCode: json['messageCode'] as String? ?? fallbackMessageCode,
      userCode: json['userCode'] as String? ?? '',
      // Confirmed against a live payload: `userName` is always null on
      // this endpoint — display name isn't available at this layer, same
      // as the realtime path (see MessageFirestoreItem's doc comment on
      // ReadReceiptEntity.userName). Callers must show a generic label
      // instead of a blank/raw-code name.
      userName: json['userName'] as String? ?? '',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      role: (json['role'] ?? json['userRole'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'messageCode': messageCode,
    'userCode': userCode,
    'userName': userName,
    if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
    if (readAt != null) 'readAt': readAt!.toIso8601String(),
    if (role != null) 'role': role,
  };

  ReadReceiptEntity toEntity() {
    return ReadReceiptEntity(
      messageCode: messageCode,
      userCode: userCode,
      userName: userName,
      deliveredAt: deliveredAt,
      readAt: readAt,
      role: role,
    );
  }
}
