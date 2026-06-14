import 'package:isar/isar.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

part 'message_entity_collection.g.dart';

/// Isar collection backing [MessageEntity].
///
/// Named [MessageEntityCollection] to avoid collision with the existing
/// [MessageCollection] which backs the legacy [Message] entity.
///
/// IMPORTANT: Do NOT touch [MessageCollection].
@collection
class MessageEntityCollection {
  Id get isarId => id;

  @Index(unique: true)
  late String code;

  // Isar requires a non-computed int Id field.
  // We store the server-assigned int id; for local-only messages
  // this is set to Isar.autoIncrement via the factory constructor.
  late int id;

  @Index()
  late String conversationCode;

  // Sender (denormalised)
  late String senderCode;
  late String senderName;

  /// Raw string; convert via [ParticipantRole.fromApiString].
  late String senderRole;
  String? senderAvatarUrl;

  // Content
  late String text;

  /// Plain-text version of [text] used for full-text prefix search.
  @Index()
  late String textPlain;

  /// Raw string; convert via [MessageType.fromApiString].
  late String messageType;

  // Status
  /// Raw string; convert via [MessageStatus.fromApiString].
  late String status;

  // Flags
  late bool isPrivate;
  late bool isEdited;
  late bool isDeleted;
  String? deletedPlaceholder;

  // Threading
  String? threadParentCode;
  String? threadParentSenderCode;
  String? threadParentSenderName;
  String? threadParentText;

  // Timestamps
  @Index()
  late DateTime sentAt;
  DateTime? editedAt;
  DateTime? deletedAt;

  // Embedded sub-documents
  List<AttachmentEntityCollection>? attachments;
  List<ReadReceiptEntityCollection>? readReceipts;

  /// Reactions stored as embedded list (userId → emoji).
  List<MessageReactionEntityCollection>? reactions;

  // Tenancy — required on every query
  @Index()
  late String organizationCode;

  @Index()
  late String schoolCode;

  // Sync metadata
  bool localOnly = false;
  bool pendingDelete = false;
  int syncAttempts = 0;
  DateTime? lastSyncedAt;

  /// Client-side temporary code assigned before the server responds.
  String? localTempCode;

  MessageEntityCollection();

  // ─── Mapping ───────────────────────────────────────────────────────────────

  factory MessageEntityCollection.fromEntity(MessageEntity entity) {
    return MessageEntityCollection()
      ..id = _parseIntId(entity.id)
      ..code = entity.code
      ..conversationCode = entity.conversationCode
      ..senderCode = entity.senderCode
      ..senderName = entity.senderName
      ..senderRole = entity.senderRole.toApiString()
      ..senderAvatarUrl = entity.senderAvatarUrl
      ..text = entity.text
      ..textPlain = _stripFormatting(entity.text)
      ..messageType = entity.messageType.toApiString()
      ..status = entity.status.toApiString()
      ..isPrivate = entity.isPrivate
      ..isEdited = entity.isEdited
      ..isDeleted = entity.isDeleted
      ..deletedPlaceholder = entity.deletedPlaceholder
      ..threadParentCode = entity.threadParentCode
      ..threadParentSenderCode = entity.threadParentSenderCode
      ..threadParentSenderName = entity.threadParentSenderName
      ..threadParentText = entity.threadParentText
      ..sentAt = entity.sentAt
      ..editedAt = entity.editedAt
      ..deletedAt = entity.deletedAt
      ..attachments = entity.attachments
          .map(AttachmentEntityCollection.fromEntity)
          .toList()
      ..readReceipts = entity.readReceipts
          .map(ReadReceiptEntityCollection.fromEntity)
          .toList()
      ..reactions = entity.reactions.entries
          .map((e) => MessageReactionEntityCollection()
            ..userCode = e.key
            ..emoji = e.value)
          .toList()
      ..organizationCode = entity.organizationCode
      ..schoolCode = entity.schoolCode
      ..localTempCode = entity.localTempCode;
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id.toString(),
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
      threadParentCode: threadParentCode,
      threadParentSenderCode: threadParentSenderCode,
      threadParentSenderName: threadParentSenderName,
      threadParentText: threadParentText,
      sentAt: sentAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      attachments: attachments?.map((e) => e.toEntity()).toList() ?? [],
      readReceipts: readReceipts?.map((e) => e.toEntity()).toList() ?? [],
      reactions: {for (final r in reactions ?? []) r.userCode: r.emoji},
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      localTempCode: localTempCode,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Parse server int id; returns 0 for non-numeric (e.g. temp UUIDs).
  static int _parseIntId(String rawId) => int.tryParse(rawId) ?? 0;

  /// Strip HTML tags and reduce whitespace for search indexing.
  static String _stripFormatting(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

@embedded
class AttachmentEntityCollection {
  late String code;
  late String messageCode;
  late String conversationCode;
  late String fileName;
  late String fileUrl;
  late String mimeType;
  late int fileSizeBytes;
  late String attachmentType;
  String? thumbnailUrl;
  String? localFilePath;
  late String uploadedBy;
  late DateTime uploadedAt;

  AttachmentEntityCollection();

  factory AttachmentEntityCollection.fromEntity(AttachmentEntity entity) {
    return AttachmentEntityCollection()
      ..code = entity.code
      ..messageCode = entity.messageCode
      ..conversationCode = entity.conversationCode
      ..fileName = entity.fileName
      ..fileUrl = entity.fileUrl
      ..mimeType = entity.mimeType
      ..fileSizeBytes = entity.fileSizeBytes
      ..attachmentType = entity.attachmentType.toApiString()
      ..thumbnailUrl = entity.thumbnailUrl
      ..localFilePath = entity.localFilePath
      ..uploadedBy = entity.uploadedBy
      ..uploadedAt = entity.uploadedAt;
  }

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
      localFilePath: localFilePath,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
    );
  }
}

@embedded
class ReadReceiptEntityCollection {
  late String messageCode;
  late String userCode;
  late String userName;
  DateTime? deliveredAt;
  DateTime? readAt;

  ReadReceiptEntityCollection();

  factory ReadReceiptEntityCollection.fromEntity(ReadReceiptEntity entity) {
    return ReadReceiptEntityCollection()
      ..messageCode = entity.messageCode
      ..userCode = entity.userCode
      ..userName = entity.userName
      ..deliveredAt = entity.deliveredAt
      ..readAt = entity.readAt;
  }

  ReadReceiptEntity toEntity() {
    return ReadReceiptEntity(
      messageCode: messageCode,
      userCode: userCode,
      userName: userName,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }
}

@embedded
class MessageReactionEntityCollection {
  late String userCode;
  late String emoji;
}
