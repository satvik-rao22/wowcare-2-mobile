import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_logger.dart';
import '../../../core/util/api_constants.dart';
import '../../../core/util/api_paths.dart';
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
    // A bare `Dio()` has NO timeouts (connect/send/receive all null), so a
    // half-open connection to storage makes this `await` hang forever — and
    // every caller sets a "uploading" flag before it, so the UI is stuck until
    // the app is killed. Storage is a plain PUT of at most a few MB, so these
    // are generous enough for a slow mobile link while still bounding a dead
    // socket.
    final uploadClient = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 1),
      ),
    );
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
    } on DioException catch (e) {
      ApiLogger.logError(
        url: logUrl,
        method: 'PUT',
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      rethrow;
    }
  }

  /// Waits only as long as it's useful for assets that are about to be
  /// **attached to a record** (task attachments, message media), and never
  /// throws. Returns false *only* when the service says an asset definitively
  /// FAILED; true otherwise, including on timeout.
  ///
  /// Deliberately different from [waitUntilAssetsReady], which blocks until
  /// every asset is literally `READY` because its callers (profile photos) must
  /// render a delivery URL the moment they return. An attachment needs none of
  /// that: the record stores the **asset code**, and the URL is resolved lazily
  /// at display time by [getMediaAssetUrlByCode] (which does its own waiting).
  ///
  /// Applying the stricter gate here made attaching impossible: document-ms
  /// leaves these assets at `UPLOADED`, `READY` never arrived, and the caller
  /// polled the session ~60 times over two minutes before failing an upload that
  /// had actually succeeded. So `UPLOADED` counts as good enough, an
  /// unrecognized session payload stops the polling immediately instead of
  /// burning the whole timeout, and a slow processing pipeline can no longer
  /// block the user from saving.
  Future<bool> awaitAssetsAttachable({
    required String sessionCode,
    required List<String> expectedAssetCodes,
    Duration pollEvery = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final expectedSet = expectedAssetCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (expectedSet.isEmpty) return true;

    final deadline = DateTime.now().add(timeout);
    while (true) {
      _UploadSessionStatusResult result;
      try {
        result = await _getUploadSessionStatus(
          sessionCode: sessionCode,
          expectedAssetCodes: expectedSet,
        );
      } catch (_) {
        // The status endpoint is a courtesy here, not a requirement.
        return true;
      }
      if (result.hasFailure) return false;
      if (result.isAttachable) return true;
      // Nothing recognizable in the payload — polling it again will not change
      // that, so stop rather than repeating the request until the deadline.
      if (result.isUnknown) return true;
      if (DateTime.now().isAfter(deadline)) return true;
      await Future.delayed(pollEvery);
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

    final deadline = DateTime.now().add(timeout);
    while (true) {
      final result = await _getUploadSessionStatus(
        sessionCode: sessionCode,
        expectedAssetCodes: expectedSet,
      );
      if (result.isReady) return;
      if (result.failureMessage != null && result.failureMessage!.isNotEmpty) {
        throw Exception(result.failureMessage);
      }
      if (DateTime.now().isAfter(deadline)) {
        throw Exception('Photo processing is taking too long. Please try again.');
      }
      await Future.delayed(pollEvery);
    }
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
      // Either the session doesn't list these assets or the payload isn't the
      // shape this parses. Flagged as *unknown* rather than "not ready" so a
      // caller can stop polling something that will never answer.
      return const _UploadSessionStatusResult(isReady: false, isUnknown: true);
    }
    var readyCount = 0;
    var attachableCount = 0;
    for (final status in statuses.values) {
      final normalized = status.trim().toUpperCase();
      if (normalized == 'READY') readyCount++;
      // Stored and acknowledged by document-ms. It may still have processing to
      // do (derivatives, virus scan), but the asset code is already usable as a
      // reference — which is all an attachment needs.
      if (normalized == 'READY' || normalized == 'UPLOADED') attachableCount++;
      if (normalized == 'FAILED') {
        return const _UploadSessionStatusResult(
          isReady: false,
          failureMessage: 'Upload processing failed',
        );
      }
    }
    return _UploadSessionStatusResult(
      isReady: readyCount == expectedAssetCodes.length,
      isAttachable: attachableCount == expectedAssetCodes.length,
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
    final deadline = DateTime.now().add(timeout);
    while (true) {
      try {
        final endpoint =
            '${ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '')}'
            '${ApiPaths.documentMediaAssetByCodePath(normalizedAssetCode)}';
        final response = await _apiClient.client.get<dynamic>(endpoint);
        final body = response.data;
        final resolved = _extractDocumentAssetUrl(body);
        if (resolved.isNotEmpty) return resolved;
      } catch (_) {
        // Keep retrying for eventual consistency after finalize.
      }
      if (DateTime.now().isAfter(deadline)) return '';
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

    // A resolution for this code is already running → share its result.
    final inFlight = _assetUrlInFlight[normalized];
    if (inFlight != null) return inFlight;

    final future = _waitForDocumentAssetUrlByCode(assetCode: normalized)
        .then((String url) {
      if (url.isNotEmpty) _assetUrlCache[normalized] = url;
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
    return UploadSessionResult(
      sessionCode: sessionCode,
      documentApiBasePath:
          documentApiBasePath.isEmpty ? '/api/v1' : documentApiBasePath,
    );
  }

  String _extractDocumentAssetUrl(dynamic body) {
    if (body is! Map) return '';
    final data = body['data'];
    if (data is! Map) return '';

    String pickFromMap(Map map) {
      final candidates = <dynamic>[
        map['deliveryUrl'],
        map['artifactUrl'],
        map['url'],
        map['thumbnailUrl'],
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
    final deadline = DateTime.now().add(timeout);
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
      if (DateTime.now().isAfter(deadline)) {
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
    final deadline = DateTime.now().add(timeout);
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
      if (DateTime.now().isAfter(deadline)) return '';
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
    final deadline = DateTime.now().add(timeout);
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
      if (DateTime.now().isAfter(deadline)) return '';
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
    final deadline = DateTime.now().add(timeout);
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
      if (DateTime.now().isAfter(deadline)) return '';
      await Future.delayed(pollEvery);
    }
  }
}

class _UploadSessionStatusResult {
  const _UploadSessionStatusResult({
    required this.isReady,
    this.isAttachable = false,
    this.isUnknown = false,
    this.failureMessage,
  });

  /// Every expected asset reports `READY` — it has a delivery URL.
  final bool isReady;

  /// Every expected asset reports `READY` *or* `UPLOADED` — stored, so its code
  /// can be attached to a record even if processing hasn't finished.
  final bool isAttachable;

  /// The session payload said nothing about the expected assets, so polling it
  /// again is pointless.
  final bool isUnknown;

  final String? failureMessage;

  bool get hasFailure =>
      failureMessage != null && failureMessage!.trim().isNotEmpty;
}

