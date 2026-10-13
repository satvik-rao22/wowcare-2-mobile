import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import '../../../core/utils/app_time.dart';

import '../../../core/observability/media_upload_trace.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_logger.dart';
import '../../../core/network/session_expired_interceptor.dart'
    show kNoAutoReplayExtraKey;
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/api_paths.dart';
import '../../../core/utils/file_utils/file_utils.dart';
import '../../../core/utils/logger_service.dart';
import 'asset_models.dart';

/// Isolate entry point: streams [path] through SHA-256 and returns the
/// base64-encoded raw digest. Streaming means even a large video is hashed
/// without loading it fully into memory. Top-level so it can run via `compute`.
Future<String> _hashFileSha256Base64(String path) async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return base64Encode(digest.bytes);
}

/// Which kind of profile a photo belongs to, for [AssetService.deleteProfilePhoto].
///
/// Declared here rather than in `asset_models.dart` because that file
/// holds only the upload-session/presign DTOs and no enums; this is the single
/// discriminator for the one method that needs it.
enum ProfilePhotoOwner { student, guardian, staff }

/// The app's asset service: everything that talks to our document service
/// about files — documents, photos, videos, chat attachments and school-cloud
/// images.
///
/// Use it for:
/// - **Uploading** — open a session for the owner (`create…UploadSession`),
///   then [uploadToSession] does presign → PUT → complete → wait until ready.
///   Profile photos go through `ProfilePhotoUploader`, which adds the
///   per-owner finalize step.
/// - **Resolving** an asset code to a display/download URL —
///   [getMediaAssetUrlByCode] (cached for 10 minutes, one request shared
///   between callers, a short cool-down for assets that aren't ready).
/// - **Deleting** a profile photo — [deleteProfilePhoto].
///
/// The individual steps (`createAssetPresign`, `uploadFileToPresignedUrl`,
/// `completeAssetUpload`, `waitUntilAssetsReady`) stay public for the
/// batch flows (chat attachments, activity media); new code should not
/// chain them by hand.
///
/// This is the one server-aware layer for files. Underneath it uses the
/// server-independent file utils (`lib/core/utils/file_utils/`) — FileUtils
/// for names and MIME types, and FileDownloadService for downloads — which
/// must never learn about our server.
class AssetService {
  AssetService(this._apiClient);

  final ApiClient _apiClient;

  /// Opts a request OUT of the shared 401-refresh auto-replay, so a token-refresh
  /// replay cannot silently create a duplicate upload session / presigned asset /
  /// completion. Applied to the non-idempotent upload mutations. See
  /// [kNoAutoReplayExtraKey].
  Options get _noReplayOptions =>
      Options(extra: const {kNoAutoReplayExtraKey: true});

  /// Caches resolved delivery URLs by asset code so the same thumbnail is not
  /// re-resolved over the network every time its widget rebuilds (e.g. on list
  /// scroll/recycling). Asset URLs are stable once finalized.
  final Map<String, String> _assetUrlCache = <String, String>{};
  final Map<String, DateTime> _assetUrlCachedAt = <String, DateTime>{};

  /// Delivery URLs are signed CDN links, so a resolved URL is reused for this
  /// long and then resolved again — never held for a whole session, where it
  /// could expire under a screen that stays open.
  @visibleForTesting
  Duration assetUrlCacheTtl = const Duration(minutes: 10);

  /// The cached URL for [assetCode] while it is still fresh, else null.
  String? _freshCachedUrl(String assetCode) {
    final url = _assetUrlCache[assetCode];
    final at = _assetUrlCachedAt[assetCode];
    if (url == null || at == null) return null;
    if (AppTime.nowUtc().difference(at) >= assetUrlCacheTtl) {
      _assetUrlCache.remove(assetCode);
      _assetUrlCachedAt.remove(assetCode);
      return null;
    }
    return url;
  }

  /// Dedupes concurrent resolutions of the same asset code so a list of cards
  /// sharing one code issues a single network call.
  final Map<String, Future<String>> _assetUrlInFlight = <String, Future<String>>{};

  /// When an asset never finishes backend processing, [_waitForDocumentAssetUrlByCode]
  /// gives up after its timeout — but on its own that's only a one-time
  /// reprieve: a chat bubble's `AttachmentUrlResolver` re-creates its State
  /// (and re-calls [getMediaAssetUrlByCode]) every time the message list
  /// rebuilds (scroll recycling, a realtime delta for any other message,
  /// the keyboard opening, …), which would otherwise restart a brand new
  /// 15-second poll loop each time — visible as the same asset code being
  /// GET-polled forever, minutes after it was first requested. Remembering
  /// *when* an asset last failed lets us skip straight back to "still
  /// unresolved" without hitting the network again until the cooldown
  /// passes.
  final Map<String, DateTime> _assetUrlFailedAt = <String, DateTime>{};
  static const Duration _assetUrlFailureCooldown = Duration(seconds: 30);

  /// Asset codes whose most recent media-asset poll reported
  /// `status: "PROCESSING"` (or similar) rather than a hard failure — lets
  /// the UI show "still processing" instead of a generic broken-image
  /// state while the backend pipeline catches up.
  final Set<String> _processingAssetCodes = <String>{};

  /// True if [assetCode]'s most recent poll found it still backend-side
  /// processing (no delivery URL yet, but not a failure either).
  bool isAssetProcessing(String assetCode) =>
      _processingAssetCodes.contains(assetCode.trim());

  Future<UploadSessionResult> createActivityUploadSession({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
    CancelToken? cancelToken,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.activitiesUploadSessions,
      ApiConstants.activityBaseUrl,
    );

    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'classroomCode': classroomCode,
        'activityTypeCode': activityTypeCode,
        'bindingMode': bindingMode,
        'studentCodes': studentCodes,
      },
      options: _noReplayOptions,
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected upload-sessions API response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Upload session creation failed',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected upload-sessions API data format');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    final documentApiBasePath =
        (data['documentApiBasePath'] ?? ApiPaths.documentUploadSessionsRoot.replaceFirst('/upload-sessions', ''))
            .toString()
            .trim();
    if (sessionCode.isEmpty) {
      throw Exception('Upload session code is missing');
    }
    return UploadSessionResult(
      sessionCode: sessionCode,
      documentApiBasePath: documentApiBasePath.isEmpty
          ? ApiPaths.documentUploadSessionsRoot.replaceFirst('/upload-sessions', '')
          : documentApiBasePath,
    );
  }

  Future<AssetPresignResult> createAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    String? checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
    CancelToken? cancelToken,
  }) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = ApiPaths.documentAssetPresignPath(
      documentApiBasePath: documentApiBasePath,
      sessionCode: sessionCode,
    );
    final endpoint = '$origin$path';

    final response = await _apiClient.client
        .post<dynamic>(
          endpoint,
          data: <String, dynamic>{
            'assets': <Map<String, dynamic>>[
              <String, dynamic>{
                'fileName': fileName,
                'contentType': contentType,
                'contentLengthBytes': contentLengthBytes,
                if ((checksumSha256 ?? '').trim().isNotEmpty)
                  'checksumSha256': checksumSha256!.trim(),
                'mediaType': mediaType,
                'ownerType': ownerType,
                'ownerCode': ownerCode,
              },
            ],
          },
          options: _noReplayOptions,
          cancelToken: cancelToken,
        )
        .catchError((error) {
          if (error is DioException) {
            final message = _extractErrorMessageFromDio(error);
            throw Exception(message);
          }
          throw error;
        });

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected assets presign API response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(message.isNotEmpty ? message : 'Assets presign failed');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected assets presign API data format');
    }

    final uploads = data['uploads'];
    if (uploads is! List || uploads.isEmpty) {
      throw Exception('Unexpected assets presign uploads format');
    }
    final firstUpload = uploads.first;
    if (firstUpload is! Map) {
      throw Exception('Unexpected assets presign upload item format');
    }

    final assetCode = (firstUpload['assetCode'] ?? '').toString().trim();
    final presignedPutUrl =
        (firstUpload['presignedPutUrl'] ?? '').toString().trim();
    if (assetCode.isEmpty || presignedPutUrl.isEmpty) {
      throw Exception('Missing assetCode or presignedPutUrl in presign response');
    }

    final rawHeaders = firstUpload['requiredHeaders'];
    final requiredHeaders = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        final k = key.toString().trim();
        final v = value.toString().trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          requiredHeaders[k] = v;
        }
      });
    }

    return AssetPresignResult(
      assetCode: assetCode,
      presignedPutUrl: presignedPutUrl,
      requiredHeaders: requiredHeaders,
    );
  }

  /// Presigns every file in [assets] under one session in a single call to
  /// the same `assets/presign/batch` endpoint [createAssetPresign] hits with
  /// just one — sending N separate presign requests (and N separate upload
  /// sessions, one per file, at the call site) is what the endpoint's own
  /// name says it isn't meant for. Results come back in the same order as
  /// [assets].
  Future<List<AssetPresignResult>> createAssetPresignBatch({
    required String sessionCode,
    required String documentApiBasePath,
    required List<AssetPresignRequest> assets,
    CancelToken? cancelToken,
  }) async {
    if (assets.isEmpty) return const [];

    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = ApiPaths.documentAssetPresignPath(
      documentApiBasePath: documentApiBasePath,
      sessionCode: sessionCode,
    );
    final endpoint = '$origin$path';

    final response = await _apiClient.client
        .post<dynamic>(
          endpoint,
          data: <String, dynamic>{
            'assets': assets
                .map(
                  (a) => <String, dynamic>{
                    'fileName': a.fileName,
                    'contentType': a.contentType,
                    'contentLengthBytes': a.contentLengthBytes,
                    if ((a.checksumSha256 ?? '').trim().isNotEmpty)
                      'checksumSha256': a.checksumSha256!.trim(),
                    'mediaType': a.mediaType,
                    'ownerType': a.ownerType,
                    'ownerCode': a.ownerCode,
                  },
                )
                .toList(),
          },
          options: _noReplayOptions,
          cancelToken: cancelToken,
        )
        .catchError((error) {
          if (error is DioException) {
            throw Exception(_extractErrorMessageFromDio(error));
          }
          throw error;
        });

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected assets presign API response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(message.isNotEmpty ? message : 'Assets presign failed');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected assets presign API data format');
    }

    final uploads = data['uploads'];
    if (uploads is! List || uploads.length != assets.length) {
      throw Exception('Unexpected assets presign uploads format');
    }

    return uploads.map((raw) {
      if (raw is! Map) {
        throw Exception('Unexpected assets presign upload item format');
      }
      final assetCode = (raw['assetCode'] ?? '').toString().trim();
      final presignedPutUrl = (raw['presignedPutUrl'] ?? '').toString().trim();
      if (assetCode.isEmpty || presignedPutUrl.isEmpty) {
        throw Exception('Missing assetCode or presignedPutUrl in presign response');
      }
      final rawHeaders = raw['requiredHeaders'];
      final requiredHeaders = <String, String>{};
      if (rawHeaders is Map) {
        rawHeaders.forEach((key, value) {
          final k = key.toString().trim();
          final v = value.toString().trim();
          if (k.isNotEmpty && v.isNotEmpty) {
            requiredHeaders[k] = v;
          }
        });
      }
      return AssetPresignResult(
        assetCode: assetCode,
        presignedPutUrl: presignedPutUrl,
        requiredHeaders: requiredHeaders,
      );
    }).toList();
  }

  String _extractErrorMessageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = (data['message'] ?? '').toString().trim();
      if (message.isNotEmpty) return message;
      final errorMessage = (data['error'] ?? '').toString().trim();
      if (errorMessage.isNotEmpty) return errorMessage;
    }
    final raw = error.message?.trim() ?? error.toString();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }

  Future<String> computeFileChecksumSha256(File file) {
    // Hash on a background isolate, streaming the file chunk-by-chunk, so a
    // large video is neither read fully into memory nor hashed on the UI
    // isolate (which froze the UI for big files). Returns the base64-encoded
    // raw SHA-256 bytes S3 expects in `x-amz-checksum-sha256`.
    return compute(_hashFileSha256Base64, file.path);
  }

  Future<void> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
    CancelToken? cancelToken,
  }) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = ApiPaths.documentAssetCompletePath(
      documentApiBasePath: documentApiBasePath,
      sessionCode: sessionCode,
      assetCode: assetCode,
    );
    final endpoint = '$origin$path';

    await _apiClient.client.post<dynamic>(
      endpoint,
      options: _noReplayOptions,
      cancelToken: cancelToken,
    );
  }

  // ── Upload timeout policy ─────────────────────────────────────────────────
  //
  // The PUT below used a bare `Dio()` with NO timeouts, so every value was
  // null and a stalled connection could hang forever with nothing surfacing to
  // the user. These bound it without killing legitimate large uploads.
  //
  // Applied PER REQUEST rather than on a shared client: `uploadClient` is
  // local to [uploadFileToPresignedUrl] (constructed on the line below and
  // never escaping it), so nothing here can affect `_apiClient.client` — the
  // shared instance every other API call uses, whose 20s connect / 30s receive
  // are deliberately tuned for JSON and would guillotine a video mid-flight.

  /// Connection establishment only — no bytes have moved yet, so this can stay
  /// tight regardless of file size.
  static const Duration _uploadConnectTimeout = Duration(seconds: 30);

  /// Waiting for S3's response AFTER the body has been sent. Dio applies
  /// `receiveTimeout` to `request.close()`, which for a PUT resolves once the
  /// response headers arrive; S3 validates the `x-amz-checksum-sha256` of a
  /// large object before answering, so this is generous rather than tight.
  static const Duration _uploadResponseTimeout = Duration(minutes: 2);

  /// Floor throughput assumed when sizing [_sendTimeoutFor].
  ///
  /// **The assumption: 128 KB/s ≈ 1 Mbit/s sustained upload** — a poor but
  /// working mobile connection. Anything slower than this for the entire
  /// transfer is treated as a stall rather than a slow success.
  ///
  /// This is the number to revisit if uploads start timing out in the field;
  /// halving it doubles the allowance.
  static const int _assumedMinUploadBytesPerSecond = 128 * 1024;

  /// Never shorter than this, so a small photo still gets a sane bound instead
  /// of a fraction of a second.
  static const Duration _minSendTimeout = Duration(seconds: 60);

  /// Absolute cap, so a wrong content length can never produce an effectively
  /// infinite timeout — the failure mode being fixed here.
  static const Duration _maxSendTimeout = Duration(minutes: 45);

  /// Sizes the send timeout to the file actually being uploaded.
  ///
  /// Dio's `sendTimeout` is NOT idle-based: it wraps the whole
  /// `request.addStream(...)` in a single `.timeout()`, so it must cover the
  /// entire body transfer, not a gap between chunks. A value tuned for JSON
  /// (the shared client's 30s) would therefore abort any video beyond a few
  /// megabytes.
  ///
  /// Derived from the payload rather than fixed at the 200 MB worst case so a
  /// 2 MB photo is not given a 28-minute rope: at the assumed floor
  /// throughput, 200 MB allows ~27 minutes and 2 MB allows the 60s minimum.
  @visibleForTesting
  static Duration sendTimeoutForBytes(int contentLengthBytes) =>
      _sendTimeoutFor(contentLengthBytes);

  static Duration _sendTimeoutFor(int contentLengthBytes) {
    if (contentLengthBytes <= 0) return _minSendTimeout;
    final seconds =
        (contentLengthBytes / _assumedMinUploadBytesPerSecond).ceil();
    final computed = Duration(seconds: seconds);
    if (computed < _minSendTimeout) return _minSendTimeout;
    if (computed > _maxSendTimeout) return _maxSendTimeout;
    return computed;
  }

  /// Uploads one [file] into an already-open upload [session] — presign, PUT
  /// the bytes, complete, and (unless [waitUntilReady] is false) wait until
  /// the server has processed it. Returns the new asset's code.
  ///
  /// Creating the session, and anything after the upload (finalize, resolve
  /// the URL), stays with the caller: each owner has its own session endpoint
  /// and follow-up.
  ///
  /// [contentType] defaults to the file's real type
  /// (FileUtils.mimeTypeOfFile); the media type (IMAGE / VIDEO / DOCUMENT) is
  /// derived from it. [onUploadProgress] reports the PUT's 0–100 %.
  Future<UploadedAsset> uploadToSession({
    required UploadSessionResult session,
    required File file,
    required AssetOwner owner,
    String? fileName,
    String? contentType,
    bool waitUntilReady = true,
    void Function(int percent)? onUploadProgress,
    CancelToken? cancelToken,
  }) async {
    final type = contentType ?? await FileUtils.mimeTypeOfFile(file.path);
    // Some session endpoints omit the base path; the document service's
    // default is /api/v1.
    final basePath = session.documentApiBasePath.trim().isEmpty
        ? '/api/v1'
        : session.documentApiBasePath;
    final presign = await createAssetPresign(
      sessionCode: session.sessionCode,
      documentApiBasePath: basePath,
      fileName: fileName ?? FileUtils.fileName(file.path),
      contentType: type,
      contentLengthBytes: await file.length(),
      mediaType: mediaTypeFor(type),
      ownerType: owner.type,
      ownerCode: owner.code,
      cancelToken: cancelToken,
    );
    await uploadFileToPresignedUrl(
      file: file,
      presignedPutUrl: presign.presignedPutUrl,
      requiredHeaders: presign.requiredHeaders,
      fallbackContentType: type,
      onProgress: onUploadProgress == null
          ? null
          : (_, _, percent) => onUploadProgress(percent.clamp(0, 100)),
      cancelToken: cancelToken,
    );
    // A server that never answers "complete" must not freeze the upload.
    await completeAssetUpload(
      sessionCode: session.sessionCode,
      assetCode: presign.assetCode,
      documentApiBasePath: basePath,
      cancelToken: cancelToken,
    ).timeout(const Duration(seconds: 30));
    if (waitUntilReady) {
      await waitUntilAssetsReady(
        sessionCode: session.sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
    }
    return UploadedAsset(assetCode: presign.assetCode);
  }

  /// The document service's media type for a MIME type.
  static String mediaTypeFor(String contentType) =>
      contentType.startsWith('image/')
      ? 'IMAGE'
      : contentType.startsWith('video/')
      ? 'VIDEO'
      : 'DOCUMENT';

  Future<void> uploadFileToPresignedUrl({
    required File file,
    required String presignedPutUrl,
    Map<String, String> requiredHeaders = const {},
    String fallbackContentType = 'image/jpeg',
    void Function(int sent, int total)? onSendProgress,
    void Function(int sentBytes, int totalBytes, int percent)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final uploadClient = Dio();
    // Stream the file instead of reading it fully into memory: a large video
    // (up to 200 MB) must not be buffered on the heap. We set Content-Length
    // explicitly so the streamed PUT is sent with a known length (not chunked),
    // which S3 requires.
    final contentLength = await file.length();
    final headers = <String, dynamic>{};
    requiredHeaders.forEach((key, value) {
      final k = key.trim();
      final v = value.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        headers[k] = v;
      }
    });
    headers.putIfAbsent('Content-Type', () => fallbackContentType);
    headers[Headers.contentLengthHeader] = contentLength;

    final putUri = Uri.parse(presignedPutUrl);
    final logUrl = '${putUri.scheme}://${putUri.host}${putUri.path}';
    ApiLogger.logRequest(
      url: logUrl,
      method: 'PUT',
      headers: headers,
      body: '<binary: $contentLength bytes>',
    );

    // The presigned URL is valid for an hour (see AssetPresignResult), so a
    // couple of short retries on a transient DNS/connection blip (no HTTP
    // response at all — e.g. "Failed host lookup" on flaky Wi-Fi/mobile
    // data) is safe. A real HTTP error response (expired/invalid signature,
    // S3-side rejection) is not retried — retrying that would just fail the
    // same way three times slower.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      MediaUploadTrace.attempt(attempt, maxAttempts);
      MediaUploadTrace.stage(
        attempt == 1 ? MediaUploadStage.putStarted : MediaUploadStage.putRetry,
      );
      try {
        final response = await uploadClient.putUri<dynamic>(
          putUri,
          // Fresh stream per attempt — a stream can only be consumed once.
          data: file.openRead(),
          options: Options(
            headers: headers,
            responseType: ResponseType.plain,
            // Set here rather than on the client so the shared API Dio is
            // untouched and each upload gets a window sized to its own payload.
            connectTimeout: _uploadConnectTimeout,
            sendTimeout: _sendTimeoutFor(contentLength),
            receiveTimeout: _uploadResponseTimeout,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
          onSendProgress: (sent, total) {
            final effectiveTotal = (total > 0) ? total : contentLength;
            if (effectiveTotal <= 0) return;
            final fraction = sent / effectiveTotal;
            final percent = (fraction * 100).clamp(0, 100).round();
            // A custom key, not a breadcrumb: this fires continuously and
            // would evict every stage marker from the 64-entry breadcrumb
            // budget. Overwriting a key is free, so a process killed mid-PUT
            // still reports exactly how many bytes had gone out.
            MediaUploadTrace.bytesUploaded(sent, effectiveTotal);
            onProgress?.call(sent, effectiveTotal, percent);
          },
          cancelToken: cancelToken,
        );
        ApiLogger.logResponse(
          url: logUrl,
          method: 'PUT',
          statusCode: response.statusCode,
          data: response.data,
        );

        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          MediaUploadTrace.stage(MediaUploadStage.putFailed);
          throw Exception('Failed to upload file to storage');
        }
        MediaUploadTrace.stage(MediaUploadStage.putSucceeded);
        return;
      } on DioException catch (e, stackTrace) {
        ApiLogger.logError(
          url: logUrl,
          method: 'PUT',
          message: e.message,
          statusCode: e.response?.statusCode,
          errorData: e.response?.data,
        );
        MediaUploadTrace.stage(MediaUploadStage.putFailed);
        // A timeout is a transient stall, not a verdict from the server, so it
        // goes through the SAME retry path as a dropped connection instead of
        // failing the upload outright. sendTimeout/receiveTimeout were absent
        // from this set, so before the timeouts above existed there was nothing
        // to classify — and adding them without this would have turned an
        // infinite hang into an immediate, un-retried failure.
        final isTransientNetworkError =
            e.response == null &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.unknown);
        final willRetry = isTransientNetworkError && attempt < maxAttempts;
        if (!willRetry && !CancelToken.isCancel(e)) {
          // Only the final, unrecoverable failure is recorded — a retried blip
          // is noise. Non-fatal: the caller surfaces it and the user can retry,
          // so it must not count against crash-free-users.
          MediaUploadTrace.failure(
            MediaUploadStage.putFailed,
            e,
            stackTrace,
          );
        }
        if (!willRetry) rethrow;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> expectedAssetCodes,
    Duration pollEvery = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final expectedSet = expectedAssetCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (expectedSet.isEmpty) return;

    MediaUploadTrace.stage(MediaUploadStage.readyPollStarted);
    final deadline = AppTime.nowUtc().add(timeout);
    while (true) {
      final result = await _getUploadSessionStatus(
        sessionCode: sessionCode,
        expectedAssetCodes: expectedSet,
      );
      if (result.isReady) {
        MediaUploadTrace.stage(MediaUploadStage.readyPollSucceeded);
        return;
      }
      if (result.failureMessage != null && result.failureMessage!.isNotEmpty) {
        // The backend's own message is not breadcrumbed — it is server text
        // that could name the asset. Only the verdict is.
        MediaUploadTrace.stageWithDetail(
          MediaUploadStage.readyPollFailed,
          'backend_reported_failure',
        );
        throw Exception(result.failureMessage);
      }
      if (AppTime.nowUtc().isAfter(deadline)) {
        // Distinct from the failure case: the audit flagged the 2-minute
        // ceiling as possibly too short for video transcoding, and this is the
        // breadcrumb that settles it.
        MediaUploadTrace.stageWithDetail(
          MediaUploadStage.readyPollFailed,
          'timeout',
        );
        throw Exception('Photo processing is taking too long. Please try again.');
      }
      await Future.delayed(pollEvery);
    }
  }

  /// Backoff schedule for [waitUntilAssetsReadyBackoff]: check immediately,
  /// then 4 quick re-checks 1.5s apart, then 12 slower re-checks 3s apart
  /// (~42s total) — fast first checks catch the common "already done by the
  /// time we ask" case without hammering the endpoint, easing off for
  /// larger files that take longer to transcode.
  static const List<Duration> _readyPollDelays = [
    Duration.zero,
    Duration(milliseconds: 1500),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 1500),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
    Duration(seconds: 3),
  ];

  static const Set<String> _terminalFailureStatuses = {
    'FAILED',
    'DELETED',
    'ABANDONED',
  };

  /// Batch-resolves [assetCodes] against `POST .../media-assets/resolve` —
  /// the same endpoint the reports download flow already uses. Returns each
  /// resolved asset's status/deliveryUrl/thumbnailUrl, keyed by assetCode.
  /// Codes missing from the response (not yet visible to the resolve
  /// endpoint) are simply absent from the result.
  Future<Map<String, ({String status, String deliveryUrl, String thumbnailUrl})>>
  resolveMediaAssets(List<String> assetCodes) async {
    final codes = assetCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (codes.isEmpty) return const {};

    final response = await _apiClient.client.post<dynamic>(
      ApiPaths.url(ApiPaths.documentMediaAssetsResolve),
      data: <String, dynamic>{'assetCodes': codes},
    );

    final body = response.data;
    final result = <String, ({String status, String deliveryUrl, String thumbnailUrl})>{};
    if (body is! Map) return result;
    final data = body['data'];
    if (data is! Map) return result;
    final assets = data['assets'];
    if (assets is! List) return result;

    for (final item in assets) {
      if (item is! Map) continue;
      final assetCode = (item['assetCode'] ?? '').toString().trim();
      if (assetCode.isEmpty) continue;
      result[assetCode] = (
        status: (item['status'] ?? '').toString().trim().toUpperCase(),
        deliveryUrl: (item['deliveryUrl'] ?? '').toString().trim(),
        thumbnailUrl: (item['thumbnailUrl'] ?? '').toString().trim(),
      );
    }
    return result;
  }

  /// Blocks until every one of [assetCodes] is `READY` (has a delivery URL),
  /// polling [resolveMediaAssets] on [_readyPollDelays]'s backoff schedule.
  /// Throws immediately on a terminal failure status (`FAILED`/`DELETED`/
  /// `ABANDONED`) for any asset, or once the schedule is exhausted without
  /// every asset reaching READY. Returns `assetCode → deliveryUrl` on
  /// success.
  Future<Map<String, String>> waitUntilAssetsReadyBackoff({
    required List<String> assetCodes,
  }) async {
    final pending = assetCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (pending.isEmpty) return const {};

    final resolved = <String, String>{};
    for (final delay in _readyPollDelays) {
      if (delay > Duration.zero) await Future.delayed(delay);

      final statuses = await resolveMediaAssets(pending.toList());
      for (final code in pending.toList()) {
        final info = statuses[code];
        if (info == null) continue;
        if (_terminalFailureStatuses.contains(info.status)) {
          throw Exception('Attachment processing failed. Please retry.');
        }
        final url = info.deliveryUrl.isNotEmpty
            ? info.deliveryUrl
            : info.thumbnailUrl;
        if (info.status == 'READY' && url.isNotEmpty) {
          resolved[code] = url;
          pending.remove(code);
        }
      }
      if (pending.isEmpty) return resolved;
    }

    throw Exception('Attachment processing took too long. Please retry.');
  }

  Future<Map<String, String>> getUploadAssetStatuses({
    required String sessionCode,
    required List<String> expectedAssetCodes,
  }) async {
    final expectedSet = expectedAssetCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (expectedSet.isEmpty) return const <String, String>{};
    final endpoint =
        '${ApiConstants.documentMsBaseUrl}${ApiPaths.documentUploadSessionPath(sessionCode)}';
    final response = await _apiClient.client.get<dynamic>(endpoint);
    return _extractUploadAssetStatuses(
      body: response.data,
      expectedAssetCodes: expectedSet,
    );
  }

  Future<_UploadSessionStatusResult> _getUploadSessionStatus({
    required String sessionCode,
    required Set<String> expectedAssetCodes,
  }) async {
    final endpoint =
        '${ApiConstants.documentMsBaseUrl}${ApiPaths.documentUploadSessionPath(sessionCode)}';
    final response = await _apiClient.client.get<dynamic>(endpoint);
    final body = response.data;
    final statuses = _extractUploadAssetStatuses(
      body: body,
      expectedAssetCodes: expectedAssetCodes,
    );
    if (statuses.isEmpty) {
      return const _UploadSessionStatusResult(isReady: false);
    }
    var readyCount = 0;
    for (final status in statuses.values) {
      final normalized = status.trim().toUpperCase();
      if (normalized == 'READY') readyCount++;
      if (normalized == 'FAILED') {
        return const _UploadSessionStatusResult(
          isReady: false,
          failureMessage: 'Upload processing failed',
        );
      }
    }
    return _UploadSessionStatusResult(
      isReady: readyCount == expectedAssetCodes.length,
    );
  }

  Map<String, String> _extractUploadAssetStatuses({
    required dynamic body,
    required Set<String> expectedAssetCodes,
  }) {
    if (body is! Map<String, dynamic>) {
      return const <String, String>{};
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const <String, String>{};
    }
    final assets = data['assets'];
    if (assets is! List) {
      return const <String, String>{};
    }

    final statuses = <String, String>{};
    for (final item in assets) {
      if (item is! Map) continue;
      final assetCode = (item['assetCode'] ?? '').toString().trim();
      if (!expectedAssetCodes.contains(assetCode)) continue;
      final status = (item['status'] ?? '').toString().trim();
      statuses[assetCode] = status.toUpperCase();
    }
    return statuses;
  }

  Future<String> createStaffProfilePhotoUploadSession({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffProfilePhotoUploadSessionPath(staffCode),
      ApiConstants.staffBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'organizationCode': organizationCode,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected upload session response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to create profile photo session',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing upload session data');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Upload session code is missing');
    }
    return sessionCode;
  }

  Future<String> finalizeStaffProfilePhoto({
    required String staffCode,
    required String assetCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffProfilePhotoFinalizePath(staffCode),
      ApiConstants.staffBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'assetCode': assetCode.trim(),
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected finalize response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to finalize profile photo',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing finalize response data');
    }
    final finalizedAssetCode =
        (data['profilePhotoAssetCode'] ?? data['assetCode'] ?? '')
            .toString()
            .trim();
    final effectiveAssetCode =
        finalizedAssetCode.isNotEmpty ? finalizedAssetCode : assetCode.trim();
    final directUrl = (data['url'] ?? '').toString().trim();
    final thumbnailUrl = (data['thumbnailUrl'] ?? '').toString().trim();
    if (directUrl.isNotEmpty) return directUrl;
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;

    final mediaAssetUrl = await _waitForDocumentAssetUrlByCode(
      assetCode: effectiveAssetCode,
    );
    if (mediaAssetUrl.isNotEmpty) return mediaAssetUrl;

    final profileUrl = await _waitForStaffProfilePhotoUrl(
      staffCode: staffCode,
    );
    if (profileUrl.isNotEmpty) return profileUrl;
    throw Exception('Profile photo URL missing after finalize');
  }

  Future<String> createStudentProfilePhotoUploadSession({
    required String studentCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentProfilePhotoUploadSessionPath(studentCode),
      ApiConstants.studentBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'organizationCode': organizationCode,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected upload session response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to create profile photo session',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing upload session data');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Upload session code is missing');
    }
    return sessionCode;
  }

  /// Bootstraps an upload session scoped to a conversation so a picked chat
  /// attachment can go through the same generic presign → S3 PUT → complete
  /// flow used by student/staff documents and activity media.
  Future<UploadSessionResult> createConversationAttachmentUploadSession({
    required String conversationCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingConversationUploadSessionPath(conversationCode.trim()),
      ApiConstants.communicationBaseUrl,
    );
    // The messaging service reads org/school from the X-Organization-Code /
    // X-School-Code headers (already attached by the API client interceptor
    // for every request) rather than query params — confirmed against the
    // working web-app request for this endpoint.
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{},
    );
    return _parseUploadSessionResponse(response.data);
  }

  /// Registers a completed document-service asset against the conversation.
  /// Required before the asset can be referenced from `sendMessage` — the
  /// messaging service tracks attachments by its own integer id, not by the
  /// document service's asset code.
  Future<int> registerConversationAttachment({
    required String conversationCode,
    required String assetCode,
    required String originalFilename,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingConversationAttachmentsPath(conversationCode.trim()),
      ApiConstants.communicationBaseUrl,
    );
    final response = await _apiClient.client
        .post<dynamic>(
          endpoint,
          data: <String, dynamic>{
            'assetCode': assetCode,
            'originalFilename': originalFilename,
            'mimeType': mimeType,
            'fileSize': fileSizeBytes,
          },
        )
        .catchError((error) {
          if (error is DioException) {
            throw Exception(_extractErrorMessageFromDio(error));
          }
          throw error;
        });

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected attachment registration response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Failed to register attachment',
      );
    }

    final data = body['data'];
    final rawId = data is Map<String, dynamic>
        ? (data['id'] ?? data['attachmentId'])
        : null;
    final attachmentId = rawId is int ? rawId : int.tryParse('$rawId');
    if (attachmentId == null) {
      throw Exception('Attachment registered but no id was returned');
    }
    return attachmentId;
  }

  /// Bootstraps a `SCHOOL_CLOUD` upload session for direct image uploads to
  /// the school's cloud gallery (owner type `SCHOOL`), reusing the same
  /// generic presign → S3 PUT → complete flow as every other upload here.
  Future<UploadSessionResult> createSchoolCloudUploadSession({
    required String schoolCode,
  }) async {
    // Built manually (not via `ApiPaths.urlWithBase`) like every other
    // document-service call in this file: the UAT gateway's generic
    // `urlWithBase`/`url()` machinery re-derives the microservice segment
    // from the path and, seeing this path already starts with `/document`
    // (itself a recognized microservice segment), treats it as the
    // ambiguous "resource name == microservice name" case and duplicates
    // it into `/api/v1/document/document/...`.
    final origin =
        ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final endpoint =
        '$origin${ApiPaths.schoolCloudUploadSessionsPath(schoolCode)}';
    final response = await _apiClient.client
        .post<dynamic>(endpoint, data: <String, dynamic>{})
        .catchError((error) {
          if (error is DioException) {
            throw Exception(_extractErrorMessageFromDio(error));
          }
          throw error;
        });
    return _parseUploadSessionResponse(response.data);
  }

  Future<UploadSessionResult> createStudentDocumentUploadSession({
    required String studentCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/student-documents/${studentCode.trim()}/upload-session',
      ApiConstants.studentBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'studentCode': studentCode.trim(),
        'schoolCode': schoolCode.trim(),
        'organizationCode': organizationCode.trim(),
      },
    );
    return _parseUploadSessionResponse(response.data);
  }

  Future<UploadSessionResult> createStaffDocumentUploadSession({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/staff-documents/${staffCode.trim()}/upload-session',
      ApiConstants.staffBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'staffCode': staffCode.trim(),
        'schoolCode': schoolCode.trim(),
        'organizationCode': organizationCode.trim(),
      },
    );
    return _parseUploadSessionResponse(response.data);
  }

  Future<String> createGuardianProfilePhotoUploadSession({
    required String guardianCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianProfilePhotoUploadSessionPath(guardianCode),
      ApiConstants.studentBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'organizationCode': organizationCode,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected upload session response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to create profile photo session',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing upload session data');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Upload session code is missing');
    }
    return sessionCode;
  }

  Future<String> finalizeStudentProfilePhoto({
    required String studentCode,
    required String sessionCode,
    required String assetCode,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentProfilePhotoFinalizePath(studentCode),
      ApiConstants.studentBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'sessionCode': sessionCode,
        'assetCode': assetCode,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected finalize response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to finalize profile photo',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing finalize response data');
    }
    final finalizedAssetCode =
        (data['profilePhotoAssetCode'] ?? data['assetCode'] ?? '')
            .toString()
            .trim();
    final effectiveAssetCode =
        finalizedAssetCode.isNotEmpty ? finalizedAssetCode : assetCode.trim();
    final url = (data['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      final mediaAssetUrl = await _waitForDocumentAssetUrlByCode(
        assetCode: effectiveAssetCode,
      );
      if (mediaAssetUrl.isNotEmpty) {
        return mediaAssetUrl;
      }
      await _waitForStudentAssetMappingAfterFinalize(
        studentCode: studentCode,
        schoolCode: schoolCode,
        expectedAssetCode: effectiveAssetCode,
      );
      final resolvedUrl = await _waitForStudentProfilePhotoUrl(
        studentCode: studentCode,
      );
      if (resolvedUrl.isEmpty) {
        throw Exception('Profile photo URL missing after finalize');
      }
      return resolvedUrl;
    }
    return url;
  }

  Future<String> finalizeGuardianProfilePhoto({
    required String guardianCode,
    required String assetCode,
    required String schoolCode,
    required String userCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianProfilePhotoFinalizePath(guardianCode),
      ApiConstants.studentBaseUrl,
    );
    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'assetCode': assetCode.trim(),
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected finalize response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to finalize profile photo',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing finalize response data');
    }
    final finalizedAssetCode =
        (data['profilePhotoAssetCode'] ?? data['assetCode'] ?? '')
            .toString()
            .trim();
    final effectiveAssetCode =
        finalizedAssetCode.isNotEmpty ? finalizedAssetCode : assetCode.trim();
    final directUrl = (data['url'] ?? '').toString().trim();
    if (directUrl.isNotEmpty) return directUrl;

    final mediaAssetUrl = await _waitForDocumentAssetUrlByCode(
      assetCode: effectiveAssetCode,
    );
    if (mediaAssetUrl.isNotEmpty) return mediaAssetUrl;

    final profileUrl = await _waitForGuardianProfilePhotoUrl(
      schoolCode: schoolCode,
      userCode: userCode,
    );
    if (profileUrl.isNotEmpty) return profileUrl;
    throw Exception('Profile photo URL missing after finalize');
  }

  /// Deletes [code]'s profile photo. Returns normally on success; the caller
  /// then runs its own post-success reset (clear the state field, forget the
  /// cached avatar URL, snackbar).
  ///
  /// Deliberately NOT opted out of the 401-refresh auto-replay (unlike the
  /// upload mutations' [_noReplayOptions]): a replayed delete is harmless —
  /// the second one just 404s, which this method already treats as
  /// "already deleted" — and opting out would suppress the refresh-then-retry
  /// that every other call gets.
  Future<void> deleteProfilePhoto({
    required ProfilePhotoOwner owner,
    required String code,
  }) async {
    final trimmedCode = code.trim();

    // One switch picks BOTH the path and the microservice host, mirroring how
    // each finalize* method pairs its own path with a base URL: staff uses
    // [ApiConstants.staffBaseUrl], student uses [ApiConstants.studentBaseUrl],
    // and guardian ALSO uses the student base (the guardian resource is served
    // by the student MS — see [finalizeGuardianProfilePhoto], which does the
    // same). URL assembly itself is the same `ApiPaths.urlWithBase(path, base)`
    // all three already use.
    late final String path;
    late final String baseUrl;
    switch (owner) {
      case ProfilePhotoOwner.student:
        path = ApiPaths.studentDeleteProfilePhotoPath(trimmedCode);
        baseUrl = ApiConstants.studentBaseUrl;
        break;
      case ProfilePhotoOwner.guardian:
        path = ApiPaths.guardianDeleteProfilePhotoPath(trimmedCode);
        baseUrl = ApiConstants.studentBaseUrl;
        break;
      case ProfilePhotoOwner.staff:
        path = ApiPaths.staffDeleteProfilePhotoPath(trimmedCode);
        baseUrl = ApiConstants.staffBaseUrl;
        break;
    }
    final endpoint = ApiPaths.urlWithBase(path, baseUrl);

    // Debug builds only (AppLogger.d no-ops in release). URL + owner only —
    // never the headers or the bearer token, which the interceptor owns.
    AppLogger.d('[photo] delete ${owner.name} photo → POST $endpoint');

    final Response<dynamic> response;
    try {
      response = await _apiClient.client.post<dynamic>(
        endpoint,
        data: const <String, dynamic>{},
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        // ALREADY DELETED — the user's intent is already satisfied, so this is
        // success, not an error. Covers double-tap and a stale UI offering
        // delete for a photo that is already gone.
        //
        // OPEN RISK: this branch cannot tell "no photo to delete" apart from
        // "no such entity". If a wrong identifier is ever passed (e.g. a `USR_*`
        // user code where the guardian endpoint wants `GUA_*`), every call would
        // 404 and this would report success while the server keeps the photo.
        // That is why step 7 verifies guardian deletion survives an app restart
        // rather than trusting the snackbar.
        AppLogger.d(
          '[photo] delete ${owner.name} $trimmedCode → 404, treating as '
          'already deleted',
        );
        return;
      }
      if (status == 401 || status == 403) {
        // Propagate untouched so the session interceptor's refresh-then-retry
        // runs exactly as it does for every other call. Logged (not swallowed)
        // so a staff my-profile scope rejection is greppable: a 403 here is the
        // signal that the endpoint refused an admin acting on someone else.
        AppLogger.w(
          '[photo] delete REJECTED $status for ${owner.name} $trimmedCode',
        );
        rethrow;
      }
      // Timeout, offline, 500, anything else: propagate unchanged. No retry
      // loop, no special-casing — same as every other delete in the app.
      rethrow;
    }

    // Same unwrap/throw shape as [finalizeStaffProfilePhoto]: a 2xx is NOT
    // success on its own, and the server's own `message` is user-showable, so
    // it is surfaced verbatim rather than replaced with a generic string.
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected delete-profile-photo response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to delete profile photo',
      );
    }
  }

  Future<String> _waitForDocumentAssetUrlByCode({
    required String assetCode,
    Duration pollEvery = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final normalizedAssetCode = assetCode.trim();
    if (normalizedAssetCode.isEmpty) return '';
    final deadline = AppTime.nowUtc().add(timeout);
    var hasLoggedFailure = false;
    while (true) {
      try {
        final endpoint =
            '${ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '')}'
            '${ApiPaths.documentMediaAssetByCodePath(normalizedAssetCode)}';
        final response = await _apiClient.client.get<dynamic>(endpoint);
        final body = response.data;
        final resolved = _extractDocumentAssetUrl(body);
        if (resolved.isNotEmpty) {
          _processingAssetCodes.remove(normalizedAssetCode);
          return resolved;
        }
        if (_extractDocumentAssetStatus(body) == 'PROCESSING') {
          _processingAssetCodes.add(normalizedAssetCode);
        }
      } catch (e) {
        // Keep retrying for eventual consistency after finalize, but log
        // once per call so a 500/expired asset doesn't crash the app and
        // doesn't spam the console once per poll tick.
        if (!hasLoggedFailure) {
          hasLoggedFailure = true;
          AppLogger.e('Media asset lookup failed for $normalizedAssetCode', e);
        }
      }
      if (AppTime.nowUtc().isAfter(deadline)) return '';
      await Future.delayed(pollEvery);
    }
  }

  /// Synchronous lookup of an already-resolved asset URL, or null if it has
  /// not been resolved yet. Lets widgets seed a FutureBuilder with cached data
  /// and skip the loading frame entirely.
  String? cachedMediaAssetUrl(String assetCode) =>
      _freshCachedUrl(assetCode.trim());

  Future<String> getMediaAssetUrlByCode({
    required String assetCode,
  }) async {
    final normalized = assetCode.trim();
    if (normalized.isEmpty) return '';

    // Resolved in the last 10 minutes → return instantly, no loader.
    final cached = _freshCachedUrl(normalized);
    if (cached != null) return cached;

    // Failed (still backend-processing/unresolvable) recently → don't hit
    // the network again until the cooldown passes, no matter how many times
    // the calling widget gets rebuilt in the meantime.
    final failedAt = _assetUrlFailedAt[normalized];
    if (failedAt != null &&
        AppTime.nowUtc().difference(failedAt) < _assetUrlFailureCooldown) {
      return '';
    }

    // A resolution for this code is already running → share its result.
    final inFlight = _assetUrlInFlight[normalized];
    if (inFlight != null) return inFlight;

    final future = _waitForDocumentAssetUrlByCode(assetCode: normalized)
        .then((String url) {
      if (url.isNotEmpty) {
        _assetUrlCache[normalized] = url;
        _assetUrlCachedAt[normalized] = AppTime.nowUtc();
        _assetUrlFailedAt.remove(normalized);
      } else {
        _assetUrlFailedAt[normalized] = AppTime.nowUtc();
      }
      return url;
    }).whenComplete(() {
      // A block body on purpose: `=> map.remove(...)` would return the
      // removed in-flight future — this very future — and whenComplete would
      // wait for it forever, so the first lookup of every code never finished.
      _assetUrlInFlight.remove(normalized);
    });

    _assetUrlInFlight[normalized] = future;
    return future;
  }

  UploadSessionResult _parseUploadSessionResponse(dynamic body) {
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected upload session response format');
    }
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Unable to create upload session',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing upload session data');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Upload session code is missing');
    }
    final documentApiBasePath = (data['documentApiBasePath'] ?? '/api/v1')
        .toString()
        .trim();
    final ownerType = (data['ownerType'] ?? '').toString().trim();
    final ownerCode = (data['ownerCode'] ?? '').toString().trim();
    return UploadSessionResult(
      sessionCode: sessionCode,
      documentApiBasePath:
          documentApiBasePath.isEmpty ? '/api/v1' : documentApiBasePath,
      ownerType: ownerType.isEmpty ? null : ownerType,
      ownerCode: ownerCode.isEmpty ? null : ownerCode,
    );
  }

  /// The document service's coarse asset status (`PROCESSING`, `READY`,
  /// `COMPLETED`, …), upper-cased for comparison. Used to tell "still
  /// being processed, normal to wait" apart from a genuine failure.
  String _extractDocumentAssetStatus(dynamic body) {
    if (body is! Map) return '';
    final data = body['data'];
    if (data is! Map) return '';
    return (data['status'] ?? '').toString().trim().toUpperCase();
  }

  String _extractDocumentAssetUrl(dynamic body) {
    if (body is! Map) return '';
    final data = body['data'];
    if (data is! Map) return '';

    // Same key set/order the activity feed trusts (attachmentUsableDeliveryUrl
    // in activity_patch_attachments.dart) — deliberately excludes a plain
    // `url` field. The document media-assets endpoint can return a stale/raw
    // `url` (e.g. the original upload reference) while `deliveryUrl` is still
    // null during processing; trusting it served a non-CDN, unservable link
    // instead of falling through to the variants below.
    String pickFromMap(Map map) {
      final candidates = <dynamic>[
        map['deliveryUrl'],
        map['thumbnailUrl'],
        map['artifactUrl'],
        map['originalDownloadUrl'],
      ];
      for (final raw in candidates) {
        final value = (raw ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final direct = pickFromMap(data);
    if (direct.isNotEmpty) return direct;

    final variants = data['variants'];
    if (variants is List) {
      for (final row in variants.whereType<Map>()) {
        final defaultVariant =
            (row['defaultVariant'] ?? false).toString().toLowerCase() == 'true';
        if (!defaultVariant) continue;
        final fromDefault = pickFromMap(row);
        if (fromDefault.isNotEmpty) return fromDefault;
      }
      for (final row in variants.whereType<Map>()) {
        final any = pickFromMap(row);
        if (any.isNotEmpty) return any;
      }
    }
    return '';
  }

  Future<void> _waitForStudentAssetMappingAfterFinalize({
    required String studentCode,
    required String schoolCode,
    required String expectedAssetCode,
    Duration pollEvery = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentProfilePhotoAssetCodes,
      ApiConstants.studentBaseUrl,
    );
    final deadline = AppTime.nowUtc().add(timeout);
    final normalizedStudent = studentCode.trim().toUpperCase();
    final normalizedExpectedAsset = expectedAssetCode.trim().toUpperCase();
    while (true) {
      try {
        final response = await _apiClient.client.get<dynamic>(
          endpoint,
          queryParameters: <String, dynamic>{
            'schoolCode': schoolCode.trim(),
            'studentCode': studentCode.trim(),
          },
        );
        final body = response.data;
        if (body is Map<String, dynamic> && body['success'] != false) {
          final data = body['data'];
          if (data is List) {
            final matched = data.cast<dynamic>().whereType<Map>().firstWhere(
              (row) =>
                  (row['studentCode'] ?? '').toString().trim().toUpperCase() ==
                  normalizedStudent,
              orElse: () => <String, dynamic>{},
            );
            final mappedAssetCode =
                (matched['assetCode'] ?? '').toString().trim().toUpperCase();
            if (mappedAssetCode.isNotEmpty &&
                (normalizedExpectedAsset.isEmpty ||
                    mappedAssetCode == normalizedExpectedAsset)) {
              return;
            }
          }
        }
      } catch (_) {
        // Do not fail fast on transient read-after-write lag or temporary fetch issues.
      }
      if (AppTime.nowUtc().isAfter(deadline)) {
        // Mapping can be eventually consistent; continue and let profile URL polling decide readiness.
        return;
      }
      await Future.delayed(pollEvery);
    }
  }

  Future<String> _waitForStudentProfilePhotoUrl({
    required String studentCode,
    Duration pollEvery = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = AppTime.nowUtc().add(timeout);
    while (true) {
      final endpoint = ApiPaths.urlWithBase(
        ApiPaths.studentProfile(studentCode),
        ApiConstants.studentBaseUrl,
      );
      final response = await _apiClient.client.get<dynamic>(endpoint);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final candidates = <dynamic>[
            data['profilePhotoUrl'],
            data['photoUrl'],
            data['profileImageUrl'],
            data['imageUrl'],
            data['url'],
          ];
          for (final raw in candidates) {
            final value = (raw ?? '').toString().trim();
            if (value.isNotEmpty) return value;
          }
        }
      }
      if (AppTime.nowUtc().isAfter(deadline)) return '';
      await Future.delayed(pollEvery);
    }
  }

  Future<String> _waitForGuardianProfilePhotoUrl({
    required String schoolCode,
    required String userCode,
    Duration pollEvery = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final normalizedSchoolCode = schoolCode.trim();
    final normalizedUserCode = userCode.trim();
    if (normalizedSchoolCode.isEmpty || normalizedUserCode.isEmpty) return '';
    final deadline = AppTime.nowUtc().add(timeout);
    while (true) {
      final endpoint = ApiPaths.urlWithBase(
        ApiPaths.guardianProfile,
        ApiConstants.studentBaseUrl,
      );
      final response = await _apiClient.client.get<dynamic>(
        endpoint,
        queryParameters: <String, dynamic>{
          'schoolCode': normalizedSchoolCode,
          'userCode': normalizedUserCode,
        },
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final candidates = <dynamic>[
            data['profilePhotoUrl'],
            data['photoUrl'],
            data['profileImageUrl'],
            data['imageUrl'],
            data['url'],
          ];
          for (final raw in candidates) {
            final value = (raw ?? '').toString().trim();
            if (value.isNotEmpty) return value;
          }
          final profilePhotoAssetCode =
              (data['profilePhotoAssetCode'] ?? '').toString().trim();
          if (profilePhotoAssetCode.isNotEmpty) {
            final resolved = await _waitForDocumentAssetUrlByCode(
              assetCode: profilePhotoAssetCode,
              timeout: const Duration(seconds: 6),
            );
            if (resolved.isNotEmpty) return resolved;
          }
        }
      }
      if (AppTime.nowUtc().isAfter(deadline)) return '';
      await Future.delayed(pollEvery);
    }
  }

  Future<String> _waitForStaffProfilePhotoUrl({
    required String staffCode,
    Duration pollEvery = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final normalized = staffCode.trim();
    if (normalized.isEmpty) return '';
    final deadline = AppTime.nowUtc().add(timeout);
    while (true) {
      final endpoint = ApiPaths.urlWithBase(
        ApiPaths.staffProfileByCodePath(normalized),
        ApiConstants.staffBaseUrl,
      );
      final response = await _apiClient.client.get<dynamic>(endpoint);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final candidates = <dynamic>[
            data['profilePhotoUrl'],
            data['photoUrl'],
            data['profileImageUrl'],
            data['imageUrl'],
            data['url'],
          ];
          for (final raw in candidates) {
            final value = (raw ?? '').toString().trim();
            if (value.isNotEmpty) return value;
          }
          final profilePhotoAssetCode =
              (data['profilePhotoAssetCode'] ?? data['photoAssetCode'] ?? '')
                  .toString()
                  .trim();
          if (profilePhotoAssetCode.isNotEmpty) {
            final resolved = await _waitForDocumentAssetUrlByCode(
              assetCode: profilePhotoAssetCode,
              timeout: const Duration(seconds: 6),
            );
            if (resolved.isNotEmpty) return resolved;
          }
        }
      }
      if (AppTime.nowUtc().isAfter(deadline)) return '';
      await Future.delayed(pollEvery);
    }
  }
}

class _UploadSessionStatusResult {
  const _UploadSessionStatusResult({
    required this.isReady,
    this.failureMessage,
  });

  final bool isReady;
  final String? failureMessage;
}

