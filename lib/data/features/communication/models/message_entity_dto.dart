import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/reaction_entry.dart';
import 'package:wowcare/core/util/app_time.dart';

part 'message_entity_dto.g.dart';

/// `DateTime.parse` with a now-fallback when absent — matches the old
/// `parse(x ?? now.toIso8601String())` helpers on the sub-DTOs.
DateTime _parseDateOrNow(Object? value) =>
    value != null ? DateTime.parse(value as String) : AppTime.nowUtc();

/// `attachmentId`/`id` alias, int-or-parse — matches the old inline expression.
Object? _readAttachmentId(Map<dynamic, dynamic> json, String key) {
  final raw = json['attachmentId'] ?? json['id'];
  return raw is int ? raw : int.tryParse('$raw');
}

/// Reaction role from `role`/`userRole`.
Object? _readReactionRole(Map<dynamic, dynamic> json, String key) =>
    (json['role'] ?? json['userRole'])?.toString();

/// MANDATE 8 SCOPE NOTE — [MessageEntityDto.fromJson] is intentionally kept
/// hand-written. It is a mapper, not a plain serializer: `id` is coerced via
/// `toString()`, many fields accept two backend key spellings, `isPrivate` is
/// derived (ppc-presence OR `isPrivate` OR `private`), and — the blocker for
/// generation — `readReceipts` is built from a SIBLING key (`json['code']`)
/// passed into [ReadReceiptEntityDto.fromJson] as a fallback, a cross-field
/// dependency `@JsonKey` cannot express. It is still a typed DTO with
/// [toEntity]; the leaf sub-DTOs it composes ([AttachmentEntityDto],
/// [ReactionDto]) ARE generated.
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

@JsonSerializable()
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

  @JsonKey(defaultValue: '')
  final String code;
  @JsonKey(defaultValue: '')
  final String messageCode;
  @JsonKey(defaultValue: '')
  final String conversationCode;
  @JsonKey(defaultValue: '')
  final String fileName;
  @JsonKey(defaultValue: '')
  final String fileUrl;
  @JsonKey(defaultValue: 'application/octet-stream')
  final String mimeType;
  @JsonKey(defaultValue: 0)
  final int fileSizeBytes;
  @JsonKey(includeIfNull: false)
  final String? thumbnailUrl;
  @JsonKey(defaultValue: '')
  final String uploadedBy;
  @JsonKey(fromJson: _parseDateOrNow)
  final DateTime uploadedAt;

  /// Messaging-service attachment id — same backend field legacy's
  /// `ChatAttachmentModel.fromJson` reads as `attachmentId`/`id`, required by
  /// `DELETE /messages/attachments/{id}`. Was previously dropped here even
  /// though the backend already returns it on every message response.
  @JsonKey(readValue: _readAttachmentId, includeIfNull: false)
  final int? attachmentId;

  factory AttachmentEntityDto.fromJson(Map<String, dynamic> json) =>
      _$AttachmentEntityDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentEntityDtoToJson(this);

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

@JsonSerializable()
class ReactionDto {
  const ReactionDto({
    required this.messageCode,
    required this.userCode,
    required this.userName,
    required this.emoji,
    required this.createdAt,
    this.role,
  });

  @JsonKey(defaultValue: '')
  final String messageCode;
  @JsonKey(defaultValue: '')
  final String userCode;
  @JsonKey(defaultValue: '')
  final String userName;
  @JsonKey(defaultValue: '')
  final String emoji;
  @JsonKey(fromJson: _parseDateOrNow)
  final DateTime createdAt;

  /// Raw backend role string (e.g. "STAFF") the reactor was acting AS —
  /// confirmed present on the reaction row as `role`/`userRole`. `toJson`
  /// always emits it (nullable, includeIfNull default), matching the old map.
  @JsonKey(readValue: _readReactionRole)
  final String? role;

  factory ReactionDto.fromJson(Map<String, dynamic> json) =>
      _$ReactionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionDtoToJson(this);
}

/// MANDATE 8 SCOPE NOTE — kept hand-written: its `fromJson` takes a
/// `fallbackMessageCode` argument (the parent message's code, unavailable on
/// the receipt row itself), which `json_serializable` factories cannot accept.
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
