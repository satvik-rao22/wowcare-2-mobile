import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../../../core/util/app_time.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_logger.dart';
import '../../../core/util/api_constants.dart';
import '../../../core/util/api_paths.dart';
import '../../../core/util/logger_service.dart';
import 'image_upload_models.dart';

class ImageUploadService {
  ImageUploadService(this._apiClient);

  final ApiClient _apiClient;

  /// Caches resolved delivery URLs by asset code so the same thumbnail is not
  /// re-resolved over the network every time its widget rebuilds (e.g. on list
  /// scroll/recycling). Asset URLs are stable once finalized.
  final Map<String, String> _assetUrlCache = <String, String>{};

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

  Future<String> computeFileChecksumSha256(File file) async {
    final bytes = await file.readAsBytes();
    // S3 `x-amz-checksum-sha256` must be base64-encoded raw SHA-256 bytes.
    return base64Encode(sha256.convert(bytes).bytes);
  }

  Future<void> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
  }) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = ApiPaths.documentAssetCompletePath(
      documentApiBasePath: documentApiBasePath,
      sessionCode: sessionCode,
      assetCode: assetCode,
    );
    final endpoint = '$origin$path';

    await _apiClient.client.post<dynamic>(endpoint);
  }

  Future<void> uploadFileToPresignedUrl({
    required File file,
    required String presignedPutUrl,
    Map<String, String> requiredHeaders = const {},
    String fallbackContentType = 'image/jpeg',
    void Function(int sent, int total)? onSendProgress,
    void Function(int sentBytes, int totalBytes, int percent)? onProgress,
  }) async {
    final uploadClient = Dio();
    final bytes = await file.readAsBytes();
    final headers = <String, dynamic>{};
    requiredHeaders.forEach((key, value) {
      final k = key.trim();
      final v = value.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        headers[k] = v;
      }
    });
    headers.putIfAbsent('Content-Type', () => fallbackContentType);

    final putUri = Uri.parse(presignedPutUrl);
    final logUrl = '${putUri.scheme}://${putUri.host}${putUri.path}';
    ApiLogger.logRequest(
      url: logUrl,
      method: 'PUT',
      headers: headers,
      body: '<binary: ${bytes.length} bytes>',
    );

    // The presigned URL is valid for an hour (see AssetPresignResult), so a
    // couple of short retries on a transient DNS/connection blip (no HTTP
    // response at all — e.g. "Failed host lookup" on flaky Wi-Fi/mobile
    // data) is safe. A real HTTP error response (expired/invalid signature,
    // S3-side rejection) is not retried — retrying that would just fail the
    // same way three times slower.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await uploadClient.putUri<dynamic>(
          putUri,
          data: bytes,
          options: Options(
            headers: headers,
            responseType: ResponseType.plain,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
          onSendProgress: (sent, total) {
            final effectiveTotal =
                (total > 0) ? total : (bytes.isNotEmpty ? bytes.length : 0);
            if (effectiveTotal <= 0) return;
            final fraction = sent / effectiveTotal;
            final percent = (fraction * 100).clamp(0, 100).round();
            onProgress?.call(sent, effectiveTotal, percent);
          },
        );
        ApiLogger.logResponse(
          url: logUrl,
          method: 'PUT',
          statusCode: response.statusCode,
          data: response.data,
        );

        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw Exception('Failed to upload file to storage');
        }
        return;
      } on DioException catch (e) {
        ApiLogger.logError(
          url: logUrl,
          method: 'PUT',
          message: e.message,
          statusCode: e.response?.statusCode,
          errorData: e.response?.data,
        );
        final isTransientNetworkError =
            e.response == null &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.unknown);
        if (!isTransientNetworkError || attempt == maxAttempts) rethrow;
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

    final deadline = AppTime.nowUtc().add(timeout);
    while (true) {
      final result = await _getUploadSessionStatus(
        sessionCode: sessionCode,
        expectedAssetCodes: expectedSet,
      );
      if (result.isReady) return;
      if (result.failureMessage != null && result.failureMessage!.isNotEmpty) {
        throw Exception(result.failureMessage);
      }
      if (AppTime.nowUtc().isAfter(deadline)) {
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
      _assetUrlCache[assetCode.trim()];

  Future<String> getMediaAssetUrlByCode({
    required String assetCode,
  }) async {
    final normalized = assetCode.trim();
    if (normalized.isEmpty) return '';

    // Already resolved this session → return instantly, no loader.
    final cached = _assetUrlCache[normalized];
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
        _assetUrlFailedAt.remove(normalized);
      } else {
        _assetUrlFailedAt[normalized] = AppTime.nowUtc();
      }
      return url;
    }).whenComplete(() => _assetUrlInFlight.remove(normalized));

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

