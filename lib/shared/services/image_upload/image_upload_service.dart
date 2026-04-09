import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_logger.dart';
import '../../../core/util/api_constants.dart';
import '../../../core/util/api_paths.dart';
import 'image_upload_models.dart';

class ImageUploadService {
  ImageUploadService(this._apiClient);

  final ApiClient _apiClient;

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

    final response = await _apiClient.client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'fileName': fileName,
        'contentType': contentType,
        'contentLengthBytes': contentLengthBytes,
        'mediaType': mediaType,
        'ownerType': ownerType,
        'ownerCode': ownerCode,
      },
    );

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

    final assetCode = (data['assetCode'] ?? '').toString().trim();
    final presignedPutUrl = (data['presignedPutUrl'] ?? '').toString().trim();
    if (assetCode.isEmpty || presignedPutUrl.isEmpty) {
      throw Exception('Missing assetCode or presignedPutUrl in presign response');
    }

    final rawHeaders = data['requiredHeaders'];
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
  }) async {
    final uploadClient = Dio();
    final bytes = await file.readAsBytes();
    final headers = <String, dynamic>{...requiredHeaders};
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

  Future<_UploadSessionStatusResult> _getUploadSessionStatus({
    required String sessionCode,
    required Set<String> expectedAssetCodes,
  }) async {
    final endpoint =
        '${ApiConstants.documentMsBaseUrl}${ApiPaths.documentUploadSessionPath(sessionCode)}';
    final response = await _apiClient.client.get<dynamic>(endpoint);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return const _UploadSessionStatusResult(isReady: false);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const _UploadSessionStatusResult(isReady: false);
    }
    final assets = data['assets'];
    if (assets is! List) {
      return const _UploadSessionStatusResult(isReady: false);
    }

    var readyCount = 0;
    for (final item in assets) {
      if (item is! Map) continue;
      final assetCode = (item['assetCode'] ?? '').toString().trim();
      if (!expectedAssetCodes.contains(assetCode)) continue;
      final status = (item['status'] ?? '').toString().trim().toUpperCase();
      if (status == 'READY') readyCount++;
      if (status == 'FAILED') {
        final failureMessage =
            (item['failureMessage'] ?? '').toString().trim();
        final failureCode = (item['failureCode'] ?? '').toString().trim();
        final message = failureMessage.isNotEmpty
            ? failureMessage
            : (failureCode.isNotEmpty
                ? 'Upload processing failed: $failureCode'
                : 'Upload processing failed');
        return _UploadSessionStatusResult(
          isReady: false,
          failureMessage: message,
        );
      }
    }
    return _UploadSessionStatusResult(
      isReady: readyCount == expectedAssetCodes.length,
    );
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

