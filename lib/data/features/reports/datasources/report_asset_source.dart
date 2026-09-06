import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/reports/models/media_asset_resolve_response.dart';

/// Turns a report's asset code into bytes on disk.
///
/// Generation and download are two separate concerns against two different
/// services — the report API hands back an asset code, and the media service
/// resolves that code to a URL once processing finishes. Keeping the polling,
/// URL normalisation and byte fetch here leaves
/// `ReportsRemoteDataSourceImpl` to the reports API itself (§6.7).
class ReportAssetSource {
  const ReportAssetSource(this._dio);

  final Dio _dio;

  static const List<Duration> _readyPollDelays = [
    Duration.zero,
    Duration(milliseconds: 600),
    Duration(milliseconds: 1200),
    Duration(milliseconds: 2000),
    Duration(milliseconds: 2500),
    Duration(seconds: 3),
    Duration(seconds: 3),
  ];

  static const Set<String> _terminalFailureStatuses = {
    'FAILED',
    'DELETED',
    'ABANDONED',
  };

  Future<String> getReportDownloadUrl(String assetCode) async {
    final cleanCode = assetCode.trim();
    AppLogger.d('Resolving asset code to get download URL: $cleanCode');

    String? lastCandidateUrl;

    for (final delay in _readyPollDelays) {
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }

      try {
        final response = await _dio.post<Map<String, dynamic>>(
          ApiPaths.url(ApiPaths.documentMediaAssetsResolve),
          data: {
            'assetCodes': [cleanCode],
          },
        );

        final asset = MediaAssetResolveResponse.fromJson(
          response.data ?? const {},
        ).firstAsset;

        if (asset == null) {
          continue;
        }

        final status = asset.normalizedStatus;

        if (_terminalFailureStatuses.contains(status)) {
          throw Exception(
            'Report processing failed on the server. Please try again.',
          );
        }

        final downloadUrl = asset.downloadUrl;
        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          lastCandidateUrl = downloadUrl;

          if (status == 'READY' || asset.hasProcessedVariant) {
            final normalized = _normalizeDownloadUrl(downloadUrl);
            AppLogger.d(
              'Asset resolved successfully (status=$status), download URL obtained: $normalized',
            );
            return normalized;
          }
        }
      } catch (e) {
        if (e is Exception &&
            e.toString().contains('Report processing failed')) {
          rethrow;
        }
        AppLogger.w('Transient error resolving report asset $cleanCode: $e');
      }
    }

    if (lastCandidateUrl != null && lastCandidateUrl.isNotEmpty) {
      final normalized = _normalizeDownloadUrl(lastCandidateUrl);
      AppLogger.d(
        'Asset polling completed, using candidate download URL: $normalized',
      );
      return normalized;
    }

    throw Exception(
      'Report is still processing. Please try again in a few moments.',
    );
  }

  String _normalizeDownloadUrl(String url) {
    var downloadUrl = url.trim();
    if (downloadUrl.isEmpty) return downloadUrl;

    // Replace template variable if present (fallback for originalDownloadUrl)
    if (downloadUrl.contains(r'${DOCUMENT_PUBLIC_BASE_URL}')) {
      final baseUrl = _dio.options.baseUrl.isNotEmpty
          ? _dio.options.baseUrl
          : ApiConstants.documentMsBaseUrl;
      downloadUrl = downloadUrl.replaceAll(
        r'${DOCUMENT_PUBLIC_BASE_URL}',
        baseUrl,
      );
      AppLogger.d('Replaced DOCUMENT_PUBLIC_BASE_URL template with: $baseUrl');
    }

    // In UAT, ensure /api/v1/media-assets/ has the /document/ prefix
    if (ApiConstants.isGatewayEnv) {
      if (downloadUrl.startsWith('/api/v1/media-assets/')) {
        downloadUrl = downloadUrl.replaceFirst(
          '/api/v1/media-assets/',
          '/api/v1/document/media-assets/',
        );
      } else if (downloadUrl.contains('://') &&
          downloadUrl.contains('/api/v1/media-assets/')) {
        downloadUrl = downloadUrl.replaceAll(
          '/api/v1/media-assets/',
          '/api/v1/document/media-assets/',
        );
      }
    }

    // If relative path, turn into full URL using ApiPaths.url
    if (downloadUrl.startsWith('/')) {
      downloadUrl = ApiPaths.url(downloadUrl);
    }

    downloadUrl = _sanitizeDownloadUrlHost(downloadUrl);
    return downloadUrl;
  }

  /// The document microservice sometimes echoes back its own internal
  /// `localhost` (or unreachable loopback) host in `deliveryUrl`/
  /// `originalDownloadUrl` instead of the public-facing one — the device
  /// can never reach that host, so rewrite scheme/host/port to the
  /// configured document-MS base URL while keeping the backend's path
  /// (e.g. `/document-ms/api/v1/media-assets/{code}/artifacts/original`)
  /// untouched.
  String _sanitizeDownloadUrlHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return url;

    final isLoopback =
        uri.host.isEmpty || uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (!isLoopback) return url;

    final documentBase = Uri.tryParse(ApiConstants.documentMsBaseUrl);
    if (documentBase == null || !documentBase.hasAuthority) return url;

    final rewritten = uri.replace(
      scheme: documentBase.scheme,
      host: documentBase.host,
      port: documentBase.hasPort ? documentBase.port : null,
    );
    AppLogger.w(
      '[REPORTS] Backend returned a loopback download URL ($url); '
      'rewriting host to ${documentBase.host}',
    );
    return rewritten.toString();
  }

  Future<List<int>> downloadReportFile(String downloadUrl) async {
    if (downloadUrl.startsWith('base64:')) {
      final base64String = downloadUrl.substring(7);
      return base64Decode(base64String);
    }

    AppLogger.d('Downloading report file from URL');

    final normalizedUrl = _normalizeDownloadUrl(downloadUrl);

    final response = await _dio.get<List<int>>(
      normalizedUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) {
      throw Exception('Failed to download report: No data received');
    }

    AppLogger.d(
      'Report file downloaded successfully: ${response.data!.length} bytes',
    );
    return response.data!;
  }
}
