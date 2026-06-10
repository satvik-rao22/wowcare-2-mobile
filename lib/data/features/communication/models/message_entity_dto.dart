import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

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
  final String organizationCode;
  final String schoolCode;

  factory MessageEntityDto.fromJson(Map<String, dynamic> json) {
    return MessageEntityDto(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      conversationCode: json['conversationCode'] as String? ?? '',
      senderCode: json['senderCode'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? 'PARENT',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      text: json['text'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      status: json['status'] as String? ?? 'SENT',
      isPrivate: json['isPrivate'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedPlaceholder: json['deletedPlaceholder'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String? ?? DateTime.now().toIso8601String()),
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt'] as String) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentEntityDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => ReactionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      readReceipts: (json['readReceipts'] as List<dynamic>?)
              ?.map((e) => ReadReceiptEntityDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      threadParentCode: json['threadParentCode'] as String?,
      threadParentSenderCode: json['threadParentSenderCode'] as String?,
      threadParentSenderName: json['threadParentSenderName'] as String?,
      threadParentText: json['threadParentText'] as String?,
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
        'text': text,
        'messageType': messageType,
        'status': status,
        'isPrivate': isPrivate,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        if (deletedPlaceholder != null) 'deletedPlaceholder': deletedPlaceholder,
        'sentAt': sentAt.toIso8601String(),
        if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'reactions': reactions.map((e) => e.toJson()).toList(),
        'readReceipts': readReceipts.map((e) => e.toJson()).toList(),
        if (threadParentCode != null) 'threadParentCode': threadParentCode,
        if (threadParentSenderCode != null) 'threadParentSenderCode': threadParentSenderCode,
        if (threadParentSenderName != null) 'threadParentSenderName': threadParentSenderName,
        if (threadParentText != null) 'threadParentText': threadParentText,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
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
      reactions: {for (final r in reactions) r.userCode: r.emoji},
      readReceipts: readReceipts.map((e) => e.toEntity()).toList(),
      threadParentCode: threadParentCode,
      threadParentSenderCode: threadParentSenderCode,
      threadParentSenderName: threadParentSenderName,
      threadParentText: threadParentText,
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

  factory AttachmentEntityDto.fromJson(Map<String, dynamic> json) {
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
        json['uploadedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
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
  });

  final String messageCode;
  final String userCode;
  final String userName;
  final String emoji;
  final DateTime createdAt;

  factory ReactionDto.fromJson(Map<String, dynamic> json) {
    return ReactionDto(
      messageCode: json['messageCode'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'messageCode': messageCode,
        'userCode': userCode,
        'userName': userName,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ReadReceiptEntityDto {
  const ReadReceiptEntityDto({
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

  factory ReadReceiptEntityDto.fromJson(Map<String, dynamic> json) {
    return ReadReceiptEntityDto(
      messageCode: json['messageCode'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'messageCode': messageCode,
        'userCode': userCode,
        'userName': userName,
        if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
        if (readAt != null) 'readAt': readAt!.toIso8601String(),
      };

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
