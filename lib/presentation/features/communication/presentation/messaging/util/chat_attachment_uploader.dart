import 'dart:io';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Uploads a picked chat attachment through the same generic upload-session
/// → presign → S3 PUT → complete flow already used for activity media and
/// student/staff documents, scoped to the owning conversation, then
/// registers the resulting asset against the conversation to obtain the
/// integer attachment id `sendMessage` requires.
class ChatAttachmentUploader {
  ChatAttachmentUploader(this._imageUploadService, this._storage);

  final ImageUploadService _imageUploadService;
  final StorageService _storage;

  /// Returns [attachment] unchanged if it has no local file to upload or is
  /// already uploaded (has both [ChatAttachment.code] and
  /// [ChatAttachment.attachmentId]). Otherwise runs it through the full
  /// pipeline and returns a copy carrying both.
  Future<ChatAttachment> upload({
    required String conversationCode,
    required ChatAttachment attachment,
  }) async {
    final localPath = attachment.localPath;
    if (attachment.isUploaded || localPath == null || localPath.isEmpty) {
      return attachment;
    }

    var step = 'CREATE_UPLOAD_SESSION';
    try {
      final organizationCode =
          (await _storage.getString(StorageKeys.organizationCode))?.trim() ?? '';
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode))?.trim() ?? '';

      final session = await _imageUploadService.createConversationAttachmentUploadSession(
        conversationCode: conversationCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
      );
      AppLogger.i(
        '[CHAT ATTACHMENT] UPLOAD SESSION CREATED — '
        'sessionCode=${session.sessionCode}, ownerType=${session.ownerType}, '
        'ownerCode=${session.ownerCode}',
      );

      step = 'PRESIGN';
      final file = File(localPath);
      final presign = await _imageUploadService.createAssetPresign(
        sessionCode: session.sessionCode,
        documentApiBasePath: session.documentApiBasePath,
        fileName: attachment.name,
        contentType: attachment.mimeType,
        contentLengthBytes: attachment.sizeBytes,
        mediaType: attachment.isImage ? 'IMAGE' : 'DOCUMENT',
        // The document service authorizes this session under the owner
        // scope it returned at session-creation time (e.g. SCHOOL) — it
        // does not recognize the conversation itself as an owner type.
        // Mirrors the web app's MessagingAttachmentUploadService.upload().
        ownerType: session.ownerType ?? 'SCHOOL',
        ownerCode: session.ownerCode ?? conversationCode,
      );
      AppLogger.i(
        '[CHAT ATTACHMENT] PRESIGN SUCCESS — assetCode=${presign.assetCode}',
      );

      step = 'S3_UPLOAD';
      await _imageUploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: attachment.mimeType,
      );
      AppLogger.i('[CHAT ATTACHMENT] S3 UPLOAD SUCCESS — assetCode=${presign.assetCode}');

      step = 'COMPLETE_ASSET';
      await _imageUploadService.completeAssetUpload(
        sessionCode: session.sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: session.documentApiBasePath,
      );
      AppLogger.i('[CHAT ATTACHMENT] ASSET COMPLETE SUCCESS — assetCode=${presign.assetCode}');

      step = 'REGISTER_ATTACHMENT';
      final attachmentId = await _imageUploadService.registerConversationAttachment(
        conversationCode: conversationCode,
        assetCode: presign.assetCode,
        originalFilename: attachment.name,
        mimeType: attachment.mimeType,
        fileSizeBytes: attachment.sizeBytes,
      );
      AppLogger.i('[CHAT ATTACHMENT] ATTACHMENT REGISTERED — attachmentId=$attachmentId');

      return attachment.copyWith(code: presign.assetCode, attachmentId: attachmentId);
    } catch (e) {
      AppLogger.e(
        '[CHAT ATTACHMENT] ATTACHMENT FLOW FAILED — '
        'step=$step, file=${attachment.name}: $e',
      );
      rethrow;
    }
  }
}
