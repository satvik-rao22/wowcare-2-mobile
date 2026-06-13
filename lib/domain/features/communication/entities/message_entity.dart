import 'package:equatable/equatable.dart';

import 'enums.dart';

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
    this.reactions = const {},
    this.readReceipts = const [],
    this.threadParentCode,
    this.threadParentSenderCode,
    this.threadParentSenderName,
    this.threadParentText,
    this.localTempCode,
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

  // Reactions: key = userCode, value = emoji
  final Map<String, String> reactions;

  // Read receipts
  final List<ReadReceiptEntity> readReceipts;

  // Status
  final MessageStatus status;

  // Private mode
  /// True when this message was sent while the sender had private mode enabled.
  /// Backend controls visibility — this flag is informational for the sender.
  final bool isPrivate;

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

  int get reactionCount => reactions.length;

  /// Emoji → count map for display.
  Map<String, int> get emojiCounts {
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  bool hasReacted(String userCode) => reactions.containsKey(userCode);
  String? getReaction(String userCode) => reactions[userCode];

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

  bool get isImage => attachmentType == AttachmentType.image;
  bool get isCached => localFilePath != null;

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
  });

  final String messageCode;
  final String userCode;
  final String userName;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [messageCode, userCode, userName, deliveredAt, readAt];
}
