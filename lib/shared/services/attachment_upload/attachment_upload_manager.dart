import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Opens the upload session for whichever domain is attaching files.
///
/// Sessions are minted by the owning service (tasks:
/// `POST /tasks/upload-session`), never by the document service directly — that
/// service-to-service call is what authorizes the domain, owner and asset
/// limits. Passing it in as a callback is what keeps this manager domain-blind
/// and reusable across tasks, events and anything else that attaches files.
typedef UploadSessionOpener = Future<UploadSessionResult> Function();

/// Uploads picked files and hands back asset codes.
///
/// Callers express intent — "upload these files" — and get back per-file
/// results. Everything between (session, batch presign, transfer, completion,
/// waiting for the asynchronous `READY` transition) is internal, so a change to
/// that flow lands in one place instead of at every call site.
///
/// Deliberate choices worth knowing:
/// * **One batched presign** for the whole set. The endpoint takes an array;
///   calling it per file costs N round trips for nothing.
/// * **Bounded concurrency.** Files stream from disk rather than buffering, and
///   only [defaultMaxConcurrent] run at once, so peak memory does not scale
///   with the number or size of attachments.
/// * **Partial success is a real outcome.** One bad file fails alone and
///   reports why; the rest still produce asset codes. Callers decide whether
///   that is good enough to save.
class AttachmentUploadManager {
  AttachmentUploadManager(this._uploadService, this._storage);

  final ImageUploadService _uploadService;
  final StorageService _storage;

  /// Enough to keep the link busy without holding many streams open at once.
  static const int defaultMaxConcurrent = 3;

  static const Duration _readyPollInterval = Duration(seconds: 2);
  static const Duration _readyTimeout = Duration(minutes: 2);

  /// Uploads [files] within a session from [openSession].
  ///
  /// [onProgress] fires on every state change so a form can render per-file
  /// progress. [waitForReady] can be turned off if the consuming API is happy
  /// to accept assets still in `UPLOADED` — that skips a multi-second wait, but
  /// only do it once the API has confirmed it tolerates non-ready codes.
  Future<AttachmentUploadState> upload({
    required List<PickedFile> files,
    required UploadSessionOpener openSession,
    String ownerType = 'SCHOOL',
    String? ownerCode,
    bool waitForReady = true,
    int maxConcurrent = defaultMaxConcurrent,
    void Function(AttachmentUploadState state)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (files.isEmpty) return const AttachmentUploadState();

    var state = AttachmentUploadState.pending(files);
    void emit() => onProgress?.call(state);
    void update(int index, AttachmentUploadItem item) {
      final items = [...state.items];
      items[index] = item;
      state = state.copyWith(items: items);
      emit();
    }

    emit();

    final UploadSessionResult session;
    try {
      session = await openSession();
    } catch (e) {
      state = state.copyWith(
        fatalError: 'Could not start the upload. ${_message(e)}',
      );
      emit();
      return state;
    }

    final resolvedOwnerCode = (ownerCode ?? '').trim().isNotEmpty
        ? ownerCode!.trim()
        : (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

    final List<AssetPresignResult> presigned;
    try {
      presigned = await _uploadService.createAssetPresignBatch(
        sessionCode: session.sessionCode,
        documentApiBasePath: session.documentApiBasePath,
        assets: files
            .map(
              (file) => AssetPresignRequest(
                fileName: file.name,
                contentType: file.mimeType,
                contentLengthBytes: file.sizeBytes,
                mediaType: file.mediaType,
                ownerType: ownerType,
                ownerCode: resolvedOwnerCode,
              ),
            )
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        fatalError: 'Could not prepare the upload. ${_message(e)}',
      );
      emit();
      return state;
    }

    // Transfer + completion, [maxConcurrent] at a time. Dart's single thread
    // makes the counter handoff safe: nothing else runs between the read and
    // the increment.
    var nextIndex = 0;
    Future<void> worker() async {
      while (true) {
        if (nextIndex >= files.length) return;
        final index = nextIndex++;
        await _transferOne(
          index: index,
          file: files[index],
          presign: presigned[index],
          session: session,
          cancelToken: cancelToken,
          currentItem: () => state.items[index],
          update: update,
        );
      }
    }

    await Future.wait(
      List.generate(math.min(maxConcurrent, files.length), (_) => worker()),
    );

    if (!waitForReady) {
      // Nothing to wait for: whatever uploaded is treated as usable as-is.
      final items = state.items
          .map(
            (item) => item.status == AttachmentUploadStatus.processing
                ? item.copyWith(status: AttachmentUploadStatus.done)
                : item,
          )
          .toList();
      state = state.copyWith(items: items);
      emit();
      return state;
    }

    state = await _awaitReady(
      state: state,
      session: session,
      emit: emit,
    );
    return state;
  }

  /// Streams one file to storage, then marks it complete.
  ///
  /// Leaves the item in `processing` — the asset is uploaded but the service has
  /// not finished finalizing it, which [_awaitReady] resolves for the batch.
  Future<void> _transferOne({
    required int index,
    required PickedFile file,
    required AssetPresignResult presign,
    required UploadSessionResult session,
    required CancelToken? cancelToken,
    required AttachmentUploadItem Function() currentItem,
    required void Function(int index, AttachmentUploadItem item) update,
  }) async {
    update(
      index,
      currentItem().copyWith(
        status: AttachmentUploadStatus.uploading,
        assetCode: presign.assetCode,
      ),
    );

    try {
      await _uploadService.uploadFileStreamedToPresignedUrl(
        file: file.file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: file.mimeType,
        cancelToken: cancelToken,
        onProgress: (sent, _) {
          // Throttled by Dio itself; only the byte count changes here so the
          // rebuild stays cheap.
          update(index, currentItem().copyWith(sentBytes: sent));
        },
      );

      await _uploadService.completeAssetUpload(
        sessionCode: session.sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: session.documentApiBasePath,
      );

      update(
        index,
        currentItem().copyWith(
          status: AttachmentUploadStatus.processing,
          sentBytes: file.sizeBytes,
        ),
      );
    } catch (e) {
      update(
        index,
        currentItem().copyWith(
          status: AttachmentUploadStatus.failed,
          error: _message(e),
        ),
      );
    }
  }

  /// Polls the session until every uploaded asset is `READY` (or has failed).
  ///
  /// One poll covers the whole batch — the session response lists every asset —
  /// so this costs the same for ten files as for one. Statuses are read
  /// per-asset rather than as a single all-or-nothing flag, so one asset failing
  /// to process does not discard the others.
  Future<AttachmentUploadState> _awaitReady({
    required AttachmentUploadState state,
    required UploadSessionResult session,
    required void Function() emit,
  }) async {
    var current = state;

    List<int> pendingIndexes() {
      final indexes = <int>[];
      for (var i = 0; i < current.items.length; i++) {
        if (current.items[i].status == AttachmentUploadStatus.processing) {
          indexes.add(i);
        }
      }
      return indexes;
    }

    if (pendingIndexes().isEmpty) return current;

    final deadline = DateTime.now().add(_readyTimeout);

    while (true) {
      final indexes = pendingIndexes();
      if (indexes.isEmpty) return current;

      final Map<String, String> statuses;
      try {
        statuses = await _uploadService.getUploadAssetStatuses(
          sessionCode: session.sessionCode,
          expectedAssetCodes: indexes
              .map((i) => current.items[i].assetCode ?? '')
              .where((code) => code.isNotEmpty)
              .toList(),
        );
      } catch (e) {
        current = _failPending(
          current,
          'Could not confirm upload. ${_message(e)}',
        );
        emit();
        return current;
      }

      final items = [...current.items];
      for (final index in indexes) {
        final code = items[index].assetCode ?? '';
        final status = (statuses[code] ?? '').toUpperCase();
        if (status == 'READY') {
          items[index] = items[index].copyWith(
            status: AttachmentUploadStatus.done,
          );
        } else if (status == 'FAILED') {
          items[index] = items[index].copyWith(
            status: AttachmentUploadStatus.failed,
            error: 'Processing failed',
          );
        }
      }
      current = current.copyWith(items: items);
      emit();

      if (pendingIndexes().isEmpty) return current;

      if (DateTime.now().isAfter(deadline)) {
        current = _failPending(
          current,
          'Processing is taking too long. Please try again.',
        );
        emit();
        return current;
      }

      await Future<void>.delayed(_readyPollInterval);
    }
  }

  /// Marks everything still `processing` as failed with [reason].
  static AttachmentUploadState _failPending(
    AttachmentUploadState state,
    String reason,
  ) {
    final items = state.items
        .map(
          (item) => item.status == AttachmentUploadStatus.processing
              ? item.copyWith(
                  status: AttachmentUploadStatus.failed,
                  error: reason,
                )
              : item,
        )
        .toList();
    return state.copyWith(items: items);
  }

  /// Trims the noise off an exception so it can be shown to a user.
  static String _message(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.cancel) return 'Upload cancelled';
      final data = error.response?.data;
      if (data is Map) {
        final message = (data['message'] ?? '').toString().trim();
        if (message.isNotEmpty) return message;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'The connection timed out';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection';
      }
      return error.message?.trim() ?? 'Upload failed';
    }
    final raw = error.toString();
    return raw.startsWith('Exception:')
        ? raw.replaceFirst('Exception:', '').trim()
        : raw;
  }
}
