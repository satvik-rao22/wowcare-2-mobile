import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Uploads picked chat attachments through the same generic upload-session
/// → presign → S3 PUT → complete flow already used for activity media and
/// student/staff documents, scoped to the owning conversation, then
/// registers the resulting assets against the conversation to obtain the
/// integer attachment ids `sendMessage` requires.
class ChatAttachmentUploader {
  ChatAttachmentUploader(this._imageUploadService, this._storage);

  final ImageUploadService _imageUploadService;
  final StorageService _storage;

  String _mediaTypeFor(ChatAttachment attachment) => attachment.isImage
      ? 'IMAGE'
      : (attachment.isVideo ? 'VIDEO' : 'DOCUMENT');

  /// Single-attachment convenience wrapper around [uploadAll].
  Future<ChatAttachment> upload({
    required String conversationCode,
    required ChatAttachment attachment,
  }) async {
    final result = await uploadAll(
      conversationCode: conversationCode,
      attachments: [attachment],
    );
    return result.single;
  }

  /// Uploads every not-yet-uploaded attachment in [attachments] together —
  /// ONE upload session, ONE batched presign call (the document service's
  /// `assets/presign/batch` endpoint is built for exactly this — presigning
  /// N files under N separate sessions one at a time, which is what calling
  /// [upload] per-file in a loop did, defeats its purpose and is why
  /// multiple picked photos/videos weren't uploading together), then the S3
  /// PUTs, asset-complete calls, and attachment registrations all run in
  /// parallel. Returns attachments in the same order as [attachments],
  /// already-uploaded ones passed through untouched.
  Future<List<ChatAttachment>> uploadAll({
    required String conversationCode,
    required List<ChatAttachment> attachments,
  }) async {
    if (attachments.isEmpty) return const [];

    // Index within `attachments` for every entry that actually needs
    // uploading, so results can be spliced back into the original order
    // alongside any already-uploaded (or file-less) entries untouched.
    final pending = <int>[];
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      final localPath = a.localPath;
      if (!a.isUploaded && localPath != null && localPath.isNotEmpty) {
        pending.add(i);
      }
    }
    if (pending.isEmpty) return attachments;

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
        'ownerCode=${session.ownerCode}, fileCount=${pending.length}',
      );
      final ownerType = session.ownerType ?? 'SCHOOL';
      final ownerCode = session.ownerCode ?? conversationCode;

      step = 'PRESIGN_BATCH';
      final presignRequests = await Future.wait(
        pending.map((i) async {
          final a = attachments[i];
          final file = File(a.localPath!);
          // S3 checksum validation needs this computed up front, same as
          // the single-file path did.
          final bytes = await file.readAsBytes();
          return AssetPresignRequest(
            fileName: a.name,
            contentType: a.mimeType,
            contentLengthBytes: a.sizeBytes,
            checksumSha256: base64Encode(sha256.convert(bytes).bytes),
            mediaType: _mediaTypeFor(a),
            ownerType: ownerType,
            ownerCode: ownerCode,
          );
        }),
      );
      final presigns = await _imageUploadService.createAssetPresignBatch(
        sessionCode: session.sessionCode,
        documentApiBasePath: session.documentApiBasePath,
        assets: presignRequests,
      );
      AppLogger.i(
        '[CHAT ATTACHMENT] PRESIGN BATCH SUCCESS — '
        'assetCodes=${presigns.map((p) => p.assetCode).toList()}',
      );

      step = 'S3_UPLOAD';
      await Future.wait(
        List.generate(pending.length, (n) {
          final a = attachments[pending[n]];
          final presign = presigns[n];
          return _imageUploadService
              .uploadFileToPresignedUrl(
                file: File(a.localPath!),
                presignedPutUrl: presign.presignedPutUrl,
                requiredHeaders: presign.requiredHeaders,
                fallbackContentType: a.mimeType,
              )
              .then(
                (_) => AppLogger.i(
                  '[CHAT ATTACHMENT] S3 UPLOAD SUCCESS — assetCode=${presign.assetCode}',
                ),
              );
        }),
      );

      step = 'COMPLETE_ASSET';
      await Future.wait(
        presigns.map(
          (presign) => _imageUploadService
              .completeAssetUpload(
                sessionCode: session.sessionCode,
                assetCode: presign.assetCode,
                documentApiBasePath: session.documentApiBasePath,
              )
              .then(
                (_) => AppLogger.i(
                  '[CHAT ATTACHMENT] ASSET COMPLETE SUCCESS — assetCode=${presign.assetCode}',
                ),
              ),
        ),
      );

      step = 'WAIT_ASSET_READY';
      // One poll covering every asset in this batch — without this,
      // attachments can get registered/sent while the document service is
      // still processing them, which is when a thumbnail/preview shows up
      // broken until the next unrelated refresh happens to re-resolve it.
      await _imageUploadService.waitUntilAssetsReady(
        sessionCode: session.sessionCode,
        expectedAssetCodes: presigns.map((p) => p.assetCode).toList(),
      );
      AppLogger.i(
        '[CHAT ATTACHMENT] ALL ASSETS READY — count=${presigns.length}',
      );

      step = 'REGISTER_ATTACHMENT';
      final attachmentIds = await Future.wait(
        List.generate(pending.length, (n) {
          final a = attachments[pending[n]];
          final presign = presigns[n];
          return _imageUploadService.registerConversationAttachment(
            conversationCode: conversationCode,
            assetCode: presign.assetCode,
            originalFilename: a.name,
            mimeType: a.mimeType,
            fileSizeBytes: a.sizeBytes,
          );
        }),
      );
      AppLogger.i(
        '[CHAT ATTACHMENT] ATTACHMENTS REGISTERED — attachmentIds=$attachmentIds',
      );

      final result = List<ChatAttachment>.from(attachments);
      for (var n = 0; n < pending.length; n++) {
        result[pending[n]] = attachments[pending[n]].copyWith(
          code: presigns[n].assetCode,
          attachmentId: attachmentIds[n],
        );
      }
      return result;
    } catch (e) {
      AppLogger.e(
        '[CHAT ATTACHMENT] ATTACHMENT FLOW FAILED — '
        'step=$step, fileCount=${pending.length}: $e',
      );
      rethrow;
    }
  }
}
