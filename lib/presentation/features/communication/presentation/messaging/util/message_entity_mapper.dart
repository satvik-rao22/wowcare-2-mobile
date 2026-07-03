import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

/// Converts a v2 [MessageEntity] into the legacy [Message] model that the
/// single shared [MessageBubble] widget renders.
///
/// This is the one place that bridges the two message domain models, so
/// both [ConversationThreadScreen] (quote/edit previews) and
/// [EntityMessageTile] (per-row rendering) stay in sync.
Message mapMessageEntityToMessage(
  MessageEntity entity,
  String currentUserCode,
) {
  // Derive delivery/read timestamps from readReceipts so the bubble shows
  // correct single/double/coloured ticks rather than always showing "sending".
  final firstDeliveredAt = entity.readReceipts
      .where((r) => r.deliveredAt != null)
      .map((r) => r.deliveredAt!)
      .firstOrNull;
  final firstReadAt = entity.readReceipts
      .where((r) => r.isRead && r.readAt != null)
      .map((r) => r.readAt!)
      .firstOrNull;

  return Message(
    id: entity.id,
    code: entity.code,
    text: entity.text,
    isSentByMe: entity.senderCode == currentUserCode,
    time: entity.sentAt,
    deliveredAt: firstDeliveredAt,
    readAt: firstReadAt,
    editedAt: entity.editedAt,
    reactions: entity.reactions,
    senderName: entity.senderName,
    senderUserCode: entity.senderCode,
    senderAvatarUrl: entity.senderAvatarUrl,
    quotedMessageId: entity.threadParentCode,
    isPrivate: entity.isPrivate,
    privateParentUserCode: entity.privateParentUserCode,
    attachments: entity.attachments
        .map(
          (a) => ChatAttachment(
            name: a.fileName,
            type: a.attachmentType == AttachmentType.image ? 'image' : 'file',
            sizeBytes: a.fileSizeBytes,
            mimeType: a.mimeType,
            remoteUrl: a.fileUrl,
            localPath: a.localFilePath,
            code: a.code,
            // Required by MessageBubble's delete-attachment flow — see
            // AttachmentEntity.attachmentId.
            attachmentId: a.attachmentId,
          ),
        )
        .toList(),
  );
}

/// Converts a locally-picked (or just-uploaded) [ChatAttachment] into an
/// [AttachmentEntity] for the optimistic [MessageEntity] shown immediately on
/// send — before, during, and after upload.
///
/// Before upload completes, [attachment.code]/[attachment.attachmentId] are
/// null and [AttachmentEntity.localFilePath] is the only renderable source
/// (`MessageBubble` already falls back to it via `ChatAttachment.displaySource`
/// once mapped back by [mapMessageEntityToMessage]).
AttachmentEntity mapChatAttachmentToAttachmentEntity(
  ChatAttachment attachment, {
  required String messageCode,
  required String conversationCode,
  required String uploadedBy,
}) {
  return AttachmentEntity(
    code: attachment.code ?? '',
    messageCode: messageCode,
    conversationCode: conversationCode,
    fileName: attachment.name,
    fileUrl: attachment.remoteUrl,
    mimeType: attachment.mimeType,
    fileSizeBytes: attachment.sizeBytes,
    attachmentType: AttachmentType.fromMimeType(attachment.mimeType),
    localFilePath: attachment.localPath,
    uploadedBy: uploadedBy,
    uploadedAt: DateTime.now(),
    attachmentId: attachment.attachmentId,
  );
}
