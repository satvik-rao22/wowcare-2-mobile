import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/logger_service.dart';
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
  String currentUserCode, {
  int recipientCount = 0,
}) {
  // Group read/delivered ticks (ALL-recipients): a group message counts as delivered/read only when
  // EVERY active recipient has delivered/read it. readReceipts only contains recipients already
  // delivered to (a recipient not yet delivered is absent), so compare their counts against the
  // total active recipient count. Setting deliveredAt/readAt drives the bubble's isDelivered/isRead
  // getters — left null (single "sent" tick) until the whole group crosses each threshold. For 1:1
  // (recipientCount == 1) this collapses to the normal single-recipient behaviour.
  DateTime? aggregatedDeliveredAt;
  DateTime? aggregatedReadAt;
  if (recipientCount > 0) {
    final deliveredCount =
        entity.readReceipts.where((r) => r.deliveredAt != null).length;
    final readCount = entity.readReceipts.where((r) => r.readAt != null).length;
    if (readCount >= recipientCount) {
      aggregatedReadAt = entity.sentAt;
      aggregatedDeliveredAt = entity.sentAt;
    } else if (deliveredCount >= recipientCount) {
      aggregatedDeliveredAt = entity.sentAt;
    }
  }
  final isMine = entity.senderCode == currentUserCode;
  AppLogger.d(
    '[CHAT OWNERSHIP v2] code=${entity.code} '
    'senderCode=${entity.senderCode} senderName=${entity.senderName} '
    'senderRole=${entity.senderRole} currentUserCode=$currentUserCode '
    'isMine=$isMine',
  );
  return Message(
    id: entity.id,
    code: entity.code,
    text: entity.text,
    isSentByMe: isMine,
    time: entity.sentAt,
    deliveredAt: aggregatedDeliveredAt,
    readAt: aggregatedReadAt,
    editedAt: entity.editedAt,
    reactions: entity.reactions,
    senderName: entity.senderName,
    senderUserCode: entity.senderCode,
    quotedMessageId: entity.threadParentCode,
    isPrivate: entity.isPrivate,
    privateParentUserCode: entity.privateParentUserCode,
    isFailed: entity.isFailed,
    hasProcessingAttachments: entity.hasProcessingAttachments,
    // In flight for the whole optimistic window — including the entire
    // upload/wait-until-ready pipeline, which now blocks the send (see
    // ChatAttachmentUploader.uploadAll) — until the server confirms or the
    // send fails.
    isSending: entity.status == MessageStatus.pending,
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
    uploadedAt: AppTime.now(),
    attachmentId: attachment.attachmentId,
  );
}
