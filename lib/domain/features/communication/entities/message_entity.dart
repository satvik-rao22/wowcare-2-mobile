import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'reaction_entry.dart';

/// Extended message entity for the communication v2.1 module.
///
/// The existing [Message] domain class is preserved untouched.
/// New repository and cubit code should use [MessageEntity].
class MessageEntity extends Equatable {
  const MessageEntity({
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
    this.localTempCode,
    this.privateParentUserCode,
  });

  // Identity
  final String id;
  final String code;

  /// The conversation this message belongs to.
  final String conversationCode;

  // Sender info (denormalised for display)
  final String senderCode;
  final String senderName;
  final ParticipantRole senderRole;
  final String? senderAvatarUrl;

  // Content
  final String text;
  final MessageType messageType;
  final List<AttachmentEntity> attachments;

  // Reactions: a flat list; a user may hold multiple distinct emojis.
  final List<ReactionEntry> reactions;

  // Read receipts
  final List<ReadReceiptEntity> readReceipts;

  // Status
  final MessageStatus status;

  // Private mode
  /// True when this message was sent while the sender had private mode enabled.
  /// Backend controls visibility — this flag is informational for the sender.
  final bool isPrivate;
  final String? privateParentUserCode;

  // Edit / delete
  final bool isEdited;
  final bool isDeleted;
  final String? deletedPlaceholder;

  // Timestamps
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  // Threading
  final String? threadParentCode;
  final String? threadParentSenderCode;
  final String? threadParentSenderName;
  final String? threadParentText;

  // Tenancy
  final String organizationCode;
  final String schoolCode;

  /// Temporary client-side code assigned before the server confirms.
  /// Null once the server has responded with a real [code].
  final String? localTempCode;

  // ─── Derived helpers ────────────────────────────────────────────────────────

  bool get isPending => status == MessageStatus.pending;
  bool get isFailed => status == MessageStatus.failed;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isThreaded => threadParentCode != null;

  /// True when at least one attachment has uploaded and registered but the
  /// document service hasn't resolved a real delivery URL for it yet — the
  /// bubble should keep showing the local preview with a "Processing" badge.
  bool get hasProcessingAttachments => attachments.any((a) => a.isProcessing);

  /// True when at least one attachment was picked but never even finished
  /// uploading (no asset code) — nothing to reconcile, only a retry (from
  /// [AttachmentEntity.localFilePath]) can recover it.
  bool get hasUnuploadedAttachments =>
      attachments.any((a) => a.code.isEmpty && a.localFilePath != null);

  int get reactionCount => reactions.length;

  /// Emoji → count map for display.
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

  MessageEntity copyWith({
    String? id,
    String? code,
    String? conversationCode,
    String? senderCode,
    String? senderName,
    ParticipantRole? senderRole,
    String? senderAvatarUrl,
    String? text,
    MessageType? messageType,
    MessageStatus? status,
    DateTime? sentAt,
    String? organizationCode,
    String? schoolCode,
    bool? isPrivate,
    bool? isEdited,
    bool? isDeleted,
    String? deletedPlaceholder,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<AttachmentEntity>? attachments,
    List<ReactionEntry>? reactions,
    List<ReadReceiptEntity>? readReceipts,
    String? threadParentCode,
    String? threadParentSenderCode,
    String? threadParentSenderName,
    String? threadParentText,
    String? localTempCode,
    String? privateParentUserCode,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      conversationCode: conversationCode ?? this.conversationCode,
      senderCode: senderCode ?? this.senderCode,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      organizationCode: organizationCode ?? this.organizationCode,
      schoolCode: schoolCode ?? this.schoolCode,
      isPrivate: isPrivate ?? this.isPrivate,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedPlaceholder: deletedPlaceholder ?? this.deletedPlaceholder,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      readReceipts: readReceipts ?? this.readReceipts,
      threadParentCode: threadParentCode ?? this.threadParentCode,
      threadParentSenderCode:
          threadParentSenderCode ?? this.threadParentSenderCode,
      threadParentSenderName:
          threadParentSenderName ?? this.threadParentSenderName,
      threadParentText: threadParentText ?? this.threadParentText,
      localTempCode: localTempCode ?? this.localTempCode,
      privateParentUserCode:
          privateParentUserCode ?? this.privateParentUserCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    conversationCode,
    senderCode,
    senderName,
    senderRole,
    senderAvatarUrl,
    text,
    messageType,
    status,
    isPrivate,
    isEdited,
    isDeleted,
    deletedPlaceholder,
    attachments,
    reactions,
    readReceipts,
    sentAt,
    editedAt,
    deletedAt,
    threadParentCode,
    threadParentSenderCode,
    threadParentSenderName,
    threadParentText,
    organizationCode,
    schoolCode,
    localTempCode,
    privateParentUserCode,
  ];
}

/// A file or media attachment on a message.
class AttachmentEntity extends Equatable {
  const AttachmentEntity({
    required this.code,
    required this.messageCode,
    required this.conversationCode,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.attachmentType,
    required this.uploadedBy,
    required this.uploadedAt,
    this.thumbnailUrl,
    this.localFilePath,
    this.attachmentId,
  });

  final String code;
  final String messageCode;
  final String conversationCode;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int fileSizeBytes;
  final AttachmentType attachmentType;
  final String? thumbnailUrl;

  /// Set when the file has been downloaded and cached locally.
  final String? localFilePath;

  final String uploadedBy;
  final DateTime uploadedAt;

  /// Messaging-service attachment id — what `DELETE /messages/attachments/{id}`
  /// expects. Distinct from [code] (the document-service asset code); null
  /// until the backend includes it on the message response (always present
  /// once the message round-trips through the API — see
  /// [MessageEntityRepository.deleteAttachment]).
  final int? attachmentId;

  bool get isImage => attachmentType == AttachmentType.image;
  bool get isCached => localFilePath != null;

  /// Uploaded and registered against the conversation (has a document-service
  /// asset [code] and messaging-service [attachmentId]) but the document
  /// service hasn't finished processing it into a real [fileUrl] yet.
  bool get isProcessing =>
      (code).isNotEmpty && attachmentId != null && fileUrl.isEmpty;

  AttachmentEntity copyWith({
    String? fileUrl,
    String? thumbnailUrl,
    bool clearLocalFilePath = false,
  }) {
    return AttachmentEntity(
      code: code,
      messageCode: messageCode,
      conversationCode: conversationCode,
      fileName: fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      attachmentType: attachmentType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localFilePath: clearLocalFilePath ? null : localFilePath,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      attachmentId: attachmentId,
    );
  }

  @override
  List<Object?> get props => [
    code,
    messageCode,
    conversationCode,
    fileName,
    fileUrl,
    mimeType,
    fileSizeBytes,
    attachmentType,
    thumbnailUrl,
    localFilePath,
    uploadedBy,
    uploadedAt,
    attachmentId,
  ];
}

/// A read receipt for a single message from a single user.
class ReadReceiptEntity extends Equatable {
  const ReadReceiptEntity({
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

  /// Raw backend role string (e.g. "STAFF", "GUARDIAN") the recipient was
  /// acting AS for this delivery/read — the REST payload carries this per
  /// receipt (`role`/`userRole`), so a dual-role account's receipt doesn't
  /// need to be guessed from the participant list.
  final String? role;

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [
    messageCode,
    userCode,
    userName,
    deliveredAt,
    readAt,
    role,
  ];
}
