import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/services/asset/asset_models.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// Uploads picked chat attachments through the same generic upload-session
/// → presign → S3 PUT → complete → register → resolve-until-ready pipeline
/// used across the app's document service, scoped to the owning
/// conversation.
///
/// A message is not sendable until every attachment reaches a real delivery
/// URL — [uploadAll] blocks on that (see [AssetService.waitUntilAssetsReadyBackoff])
/// so recipients never see a message with a permanently-spinning image.
///
/// Every network step below runs through the SAME plan regardless of how
/// many attachments there are: capped-concurrency batches (see
/// [_runCapped]) plus a hard per-call [_networkTimeout] — a batch of N
/// attachments is not "the single-attachment path repeated with more raw
/// `Future.wait` fan-out"; it is the identical bounded pipeline applied to
/// however many items came in. Without the timeout, a backend stall on any
/// one concurrent call (observed on `complete` when several assets in the
/// same session complete at once) hung [uploadAll] forever with no
/// exception ever thrown — the message just sat there silently instead of
/// surfacing as a failed/retryable send.
class ChatAttachmentUploader {
  ChatAttachmentUploader(this._assetService, this._storage);

  final AssetService _assetService;
  final StorageService _storage;

  /// Caps concurrent requests per step (S3 PUT, complete, register) so a
  /// 10-image message doesn't open 10 parallel requests at once.
  static const int _uploadConcurrency = 3;

  /// Applied to every individual network call in the pipeline below. A
  /// stalled request now fails loudly (caught, logged, surfaced as
  /// "Failed · Retry") instead of leaving [uploadAll] awaiting forever.
  static const Duration _networkTimeout = Duration(seconds: 30);

  String _mediaTypeFor(ChatAttachment attachment) => attachment.isImage
      ? 'IMAGE'
      : (attachment.isVideo ? 'VIDEO' : 'DOCUMENT');

  Future<T> _withTimeout<T>(Future<T> future, String what) {
    return future.timeout(
      _networkTimeout,
      onTimeout: () => throw Exception('Timed out $what'),
    );
  }

  /// Runs [action] over [items] with at most [_uploadConcurrency] in flight
  /// at once, preserving [items]' order in the returned list. The SAME
  /// worker-pool shape is used for every step of [uploadAll] (S3 PUT,
  /// complete, register) — see the class doc comment.
  Future<List<R>> _runCapped<T, R>(
    List<T> items,
    Future<R> Function(T item) action,
  ) async {
    final results = List<R?>.filled(items.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex;
        if (i >= items.length) return;
        nextIndex++;
        results[i] = await action(items[i]);
      }
    }

    await Future.wait(
      List.generate(_uploadConcurrency.clamp(1, items.length), (_) => worker()),
    );
    return results.cast<R>();
  }

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

  /// Uploads/registers/resolves every not-yet-ready attachment in
  /// [attachments], classifying each one so a retry never redoes finished
  /// work:
  ///
  /// - already has a delivery URL → left untouched, no calls made.
  /// - has an asset [ChatAttachment.code] but no [ChatAttachment.attachmentId]
  ///   → the bytes are already in S3 (a prior attempt died between register
  ///   and resolve, or resumed after being persisted with only the code) —
  ///   re-registers only, no re-upload.
  /// - otherwise (has a local [ChatAttachment.localPath], no code yet) →
  ///   full pipeline: session → presign(batch) → S3 PUT (capped concurrency)
  ///   → complete (capped concurrency) → register (capped concurrency).
  ///
  /// Every asset that needed registering (freshly uploaded or
  /// register-only) is then polled via
  /// [AssetService.waitUntilAssetsReadyBackoff] — this call does not
  /// return until every attachment has a real delivery URL, or throws.
  /// Returns attachments in the same order as [attachments], each with
  /// [ChatAttachment.remoteUrl] set to its resolved delivery URL.
  Future<List<ChatAttachment>> uploadAll({
    required String conversationCode,
    required List<ChatAttachment> attachments,
  }) async {
    if (attachments.isEmpty) return const [];

    final needsFullUpload = <int>[];
    final needsRegisterOnly = <int>[];
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      if (a.remoteUrl.isNotEmpty) continue; // already ready
      final assetCode = (a.code ?? '').trim();
      if (assetCode.isNotEmpty && a.attachmentId == null) {
        needsRegisterOnly.add(i);
      } else if (assetCode.isEmpty &&
          a.localPath != null &&
          a.localPath!.isNotEmpty) {
        needsFullUpload.add(i);
      }
    }
    if (needsFullUpload.isEmpty && needsRegisterOnly.isEmpty) {
      return attachments;
    }

    var step = 'CREATE_UPLOAD_SESSION';
    try {
      final organizationCode =
          (await _storage.getString(StorageKeys.organizationCode))?.trim() ?? '';
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode))?.trim() ?? '';

      final result = List<ChatAttachment>.from(attachments);
      // assetCode -> index in `attachments`, for every asset that will need
      // resolving (freshly uploaded or register-only) once registered.
      final toResolve = <String, int>{};

      if (needsFullUpload.isNotEmpty) {
        final session = await _withTimeout(
          _assetService.createConversationAttachmentUploadSession(
            conversationCode: conversationCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
          ),
          'creating the upload session',
        );
        AppLogger.i(
          '[CHAT ATTACHMENT] UPLOAD SESSION CREATED — '
          'sessionCode=${session.sessionCode}, ownerType=${session.ownerType}, '
          'ownerCode=${session.ownerCode}, fileCount=${needsFullUpload.length}',
        );
        final ownerType = session.ownerType ?? 'SCHOOL';
        final ownerCode = session.ownerCode ?? conversationCode;

        step = 'PRESIGN_BATCH';
        final presignRequests = await Future.wait(
          needsFullUpload.map((i) async {
            final a = attachments[i];
            final file = File(a.localPath!);
            // S3 checksum validation needs this computed up front.
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
        final presigns = await _withTimeout(
          _assetService.createAssetPresignBatch(
            sessionCode: session.sessionCode,
            documentApiBasePath: session.documentApiBasePath,
            assets: presignRequests,
          ),
          'presigning ${presignRequests.length} asset(s)',
        );
        AppLogger.i(
          '[CHAT ATTACHMENT] PRESIGN BATCH SUCCESS — '
          'assetCodes=${presigns.map((p) => p.assetCode).toList()}',
        );

        step = 'S3_UPLOAD';
        await _runCapped(List.generate(needsFullUpload.length, (n) => n), (n) {
          final a = attachments[needsFullUpload[n]];
          final presign = presigns[n];
          return _withTimeout(
            _assetService.uploadFileToPresignedUrl(
              file: File(a.localPath!),
              presignedPutUrl: presign.presignedPutUrl,
              requiredHeaders: presign.requiredHeaders,
              fallbackContentType: a.mimeType,
            ),
            'uploading ${presign.assetCode} to storage',
          ).then(
            (_) => AppLogger.i(
              '[CHAT ATTACHMENT] S3 UPLOAD SUCCESS — assetCode=${presign.assetCode}',
            ),
          );
        });

        step = 'COMPLETE_ASSET';
        await _runCapped(presigns, (presign) {
          return _withTimeout(
            _assetService.completeAssetUpload(
              sessionCode: session.sessionCode,
              assetCode: presign.assetCode,
              documentApiBasePath: session.documentApiBasePath,
            ),
            'completing upload for ${presign.assetCode}',
          ).then(
            (_) => AppLogger.i(
              '[CHAT ATTACHMENT] ASSET COMPLETE SUCCESS — assetCode=${presign.assetCode}',
            ),
          );
        });

        step = 'REGISTER_ATTACHMENT';
        final attachmentIds = await _runCapped(
          List.generate(needsFullUpload.length, (n) => n),
          (n) {
            final presign = presigns[n];
            final a = attachments[needsFullUpload[n]];
            return _withTimeout(
              _assetService.registerConversationAttachment(
                conversationCode: conversationCode,
                assetCode: presign.assetCode,
                originalFilename: a.name,
                mimeType: a.mimeType,
                fileSizeBytes: a.sizeBytes,
              ),
              'registering ${presign.assetCode}',
            ).then(
              (id) {
                AppLogger.i(
                  '[CHAT ATTACHMENT] ATTACHMENT REGISTERED — '
                  'assetCode=${presign.assetCode}, attachmentId=$id',
                );
                return id;
              },
            );
          },
        );
        for (var n = 0; n < needsFullUpload.length; n++) {
          final idx = needsFullUpload[n];
          final presign = presigns[n];
          result[idx] = attachments[idx].copyWith(
            code: presign.assetCode,
            attachmentId: attachmentIds[n],
          );
          toResolve[presign.assetCode] = idx;
        }
      }

      if (needsRegisterOnly.isNotEmpty) {
        step = 'REGISTER_ATTACHMENT';
        final attachmentIds = await _runCapped(needsRegisterOnly, (idx) {
          final a = attachments[idx];
          final assetCode = a.code!.trim();
          return _withTimeout(
            _assetService.registerConversationAttachment(
              conversationCode: conversationCode,
              assetCode: assetCode,
              originalFilename: a.name,
              mimeType: a.mimeType,
              fileSizeBytes: a.sizeBytes,
            ),
            'registering $assetCode',
          );
        });
        for (var n = 0; n < needsRegisterOnly.length; n++) {
          final idx = needsRegisterOnly[n];
          final assetCode = attachments[idx].code!.trim();
          result[idx] = attachments[idx].copyWith(attachmentId: attachmentIds[n]);
          toResolve[assetCode] = idx;
        }
      }
      AppLogger.i(
        '[CHAT ATTACHMENT] ATTACHMENTS REGISTERED — assetCodes=${toResolve.keys.toList()}',
      );

      // Don't publish before ready: block until every registered asset has
      // a real delivery URL.
      step = 'WAIT_ASSET_READY';
      final deliveryUrls = await _assetService.waitUntilAssetsReadyBackoff(
        assetCodes: toResolve.keys.toList(),
      );
      for (final entry in toResolve.entries) {
        final url = deliveryUrls[entry.key];
        if (url != null && url.isNotEmpty) {
          result[entry.value] = result[entry.value].copyWith(remoteUrl: url);
        }
      }
      AppLogger.i('[CHAT ATTACHMENT] ALL ASSETS READY — count=${toResolve.length}');

      return result;
    } catch (e) {
      AppLogger.e(
        '[CHAT ATTACHMENT] ATTACHMENT FLOW FAILED — '
        'step=$step, fileCount=${needsFullUpload.length + needsRegisterOnly.length}: $e',
      );
      rethrow;
    }
  }

  /// Best-effort, non-throwing re-check for a message that already sent but
  /// has an attachment still `PROCESSING` (the wait in [uploadAll] itself
  /// hit its budget and gave up rather than the send having failed outright)
  /// — used by [ConversationThreadCubit.retrySendMessage]'s manual "still
  /// processing" retry path, and by resuming into a conversation where a
  /// prior visit left something unresolved. Never throws; entries that
  /// aren't resolvable yet come back unchanged.
  Future<List<ChatAttachment>> resolveDeliveryUrls(
    List<ChatAttachment> attachments,
  ) async {
    final codes = attachments
        .map((a) => (a.code ?? '').trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (codes.isEmpty) return attachments;

    Map<String, ({String status, String deliveryUrl, String thumbnailUrl})> resolved;
    try {
      resolved = await _assetService.resolveMediaAssets(codes);
    } catch (_) {
      return attachments;
    }

    return attachments.map((a) {
      if (a.remoteUrl.isNotEmpty) return a;
      final assetCode = (a.code ?? '').trim();
      if (assetCode.isEmpty) return a;
      final info = resolved[assetCode];
      if (info == null) return a;
      final url = info.deliveryUrl.isNotEmpty ? info.deliveryUrl : info.thumbnailUrl;
      if (info.status != 'READY' || url.isEmpty) return a;
      return a.copyWith(remoteUrl: url);
    }).toList();
  }
}
