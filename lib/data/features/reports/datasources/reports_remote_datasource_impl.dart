import 'package:dio/dio.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/storage_keys.dart' as storage_keys;
import '../models/report_response_model.dart';
import '../models/recent_report_model.dart';
import 'reports_remote_datasource.dart';

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl(
    this._dio,
    this._storageService,
  );

  final Dio _dio;
  final StorageService _storageService;

  @override
  Future<ReportResponseModel> generateReport({
    required String reportType,
    required Map<String, dynamic> requestBody,
  }) async {
    // Determine endpoint based on report type
    late String endpoint;

    // Billing reports (accounts MS). Checked first because STUDENT_BILLING_MAPPING would
    // otherwise match the STUDENT_ attendance branch below.
    const billingReportTypes = <String>{
      'TRANSACTION',
      'INVOICE',
      'PAYMENT_SUMMARY',
      'OUTSTANDING',
      'REFUND',
      'STUDENT_BILLING_MAPPING',
    };

    if (billingReportTypes.contains(reportType)) {
      endpoint = ApiPaths.billingReportGenerate;
    } else if (reportType.startsWith('STUDENT_')) {
      // Student attendance reports
      endpoint = ApiPaths.studentAttendanceReportsGenerate;
    } else if (reportType.startsWith('STAFF_')) {
      if (reportType == 'STAFF_DETAILS') {
        // Staff directory
        endpoint = ApiPaths.staffReportsGenerate;
      } else {
        // Staff attendance reports
        endpoint = ApiPaths.staffAttendanceReportsGenerate;
      }
    } else if (reportType == 'STUDENTS_AND_FAMILY' ||
        reportType == 'EMERGENCY_CONTACTS' ||
        reportType == 'STUDENT_INCIDENT' ||
        reportType == 'ANNUAL_STATE_IMMUNIZATION') {
      // Student management reports
      endpoint = ApiPaths.studentManagementReportsGenerate;
    } else if (reportType == 'IMMUNIZATION') {
      // Immunization report
      endpoint = ApiPaths.studentImmunizationReport;
    } else {
      throw ArgumentError('Unknown report type: $reportType');
    }

    AppLogger.d('Posting to $endpoint with payload: $requestBody');
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.url(endpoint),
      data: requestBody,
    );

    final responseData = response.data ?? {};
    AppLogger.d('Response from $endpoint: $responseData');
    return ReportResponseModel.fromJson(responseData);
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentAttendanceReports() async {
    final schoolCode =
        await _storageService.getString(storage_keys.StorageKeys.schoolCode);
    final endpoint = ApiPaths.studentAttendanceReportsRecent;
    AppLogger.d('[REPORTS] Student Attendance API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.url(endpoint),
        queryParameters: {'schoolCode': schoolCode},
      );

      final data = response.data ?? {};
      AppLogger.d('[REPORTS] Student Attendance API: Raw response keys=${data.keys.toList()}');

      // Try multiple response format possibilities
      List? reportsList;

      // Try data['reports'] first (original format)
      reportsList = data['reports'] as List?;
      if (reportsList != null) {
        AppLogger.d('[REPORTS] Student Attendance Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data'] (alternative format)
      final dataField = data['data'];
      if (dataField is List) {
        reportsList = dataField;
        AppLogger.d('[REPORTS] Student Attendance Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data']['reports'] (nested format)
      if (dataField is Map) {
        reportsList = dataField['reports'] as List?;
        if (reportsList != null) {
          AppLogger.d('[REPORTS] Student Attendance Reports Count: ${reportsList.length}');
          return reportsList
              .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      AppLogger.d('[REPORTS] Student Attendance Reports Count: 0 (no reports array found)');
      return [];
    } catch (e) {
      AppLogger.e('[REPORTS] Student Attendance Reports Error: $e');
      return [];
    }
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffAttendanceReports() async {
    final schoolCode =
        await _storageService.getString(storage_keys.StorageKeys.schoolCode);
    final endpoint = ApiPaths.staffAttendanceReportsRecent;
    AppLogger.d('[REPORTS] Staff Attendance API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.url(endpoint),
        queryParameters: {'schoolCode': schoolCode},
      );

      final data = response.data ?? {};
      AppLogger.d('[REPORTS] Staff Attendance API: Raw response keys=${data.keys.toList()}');

      // Try multiple response format possibilities
      List? reportsList;

      // Try data['reports'] first (original format)
      reportsList = data['reports'] as List?;
      if (reportsList != null) {
        AppLogger.d('[REPORTS] Staff Attendance Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data'] (alternative format)
      final dataField = data['data'];
      if (dataField is List) {
        reportsList = dataField;
        AppLogger.d('[REPORTS] Staff Attendance Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data']['reports'] (nested format)
      if (dataField is Map) {
        reportsList = dataField['reports'] as List?;
        if (reportsList != null) {
          AppLogger.d('[REPORTS] Staff Attendance Reports Count: ${reportsList.length}');
          return reportsList
              .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      AppLogger.d('[REPORTS] Staff Attendance Reports Count: 0 (no reports array found)');
      return [];
    } catch (e) {
      AppLogger.e('[REPORTS] Staff Attendance Reports Error: $e');
      return [];
    }
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffReports() async {
    final schoolCode =
        await _storageService.getString(storage_keys.StorageKeys.schoolCode);
    final endpoint = ApiPaths.staffReportsRecent;
    AppLogger.d('[REPORTS] Staff Reports API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.url(endpoint),
        queryParameters: {'schoolCode': schoolCode},
      );

      final data = response.data ?? {};
      AppLogger.d('[REPORTS] Staff Reports API: Raw response keys=${data.keys.toList()}');

      // Try multiple response format possibilities
      List? reportsList;

      // Try data['reports'] first (original format)
      reportsList = data['reports'] as List?;
      if (reportsList != null) {
        AppLogger.d('[REPORTS] Staff Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data'] (alternative format)
      final dataField = data['data'];
      if (dataField is List) {
        reportsList = dataField;
        AppLogger.d('[REPORTS] Staff Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data']['reports'] (nested format)
      if (dataField is Map) {
        reportsList = dataField['reports'] as List?;
        if (reportsList != null) {
          AppLogger.d('[REPORTS] Staff Reports Count: ${reportsList.length}');
          return reportsList
              .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      AppLogger.d('[REPORTS] Staff Reports Count: 0 (no reports array found)');
      return [];
    } catch (e) {
      AppLogger.e('[REPORTS] Staff Reports Error: $e');
      return [];
    }
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentManagementReports() async {
    final schoolCode =
        await _storageService.getString(storage_keys.StorageKeys.schoolCode);
    final endpoint = ApiPaths.studentManagementReportsRecent;
    AppLogger.d('[REPORTS] Student Management API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.url(endpoint),
        queryParameters: {'schoolCode': schoolCode},
      );

      final data = response.data ?? {};
      AppLogger.d('[REPORTS] Student Management API: Raw response keys=${data.keys.toList()}');

      // Try multiple response format possibilities
      List? reportsList;

      // Try data['reports'] first (original format)
      reportsList = data['reports'] as List?;
      if (reportsList != null) {
        AppLogger.d('[REPORTS] Student Management Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data'] (alternative format)
      final dataField = data['data'];
      if (dataField is List) {
        reportsList = dataField;
        AppLogger.d('[REPORTS] Student Management Reports Count: ${reportsList.length}');
        return reportsList
            .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Try data['data']['reports'] (nested format)
      if (dataField is Map) {
        reportsList = dataField['reports'] as List?;
        if (reportsList != null) {
          AppLogger.d('[REPORTS] Student Management Reports Count: ${reportsList.length}');
          return reportsList
              .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      AppLogger.d('[REPORTS] Student Management Reports Count: 0 (no reports array found)');
      return [];
    } catch (e) {
      AppLogger.e('[REPORTS] Student Management Reports Error: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getStudentTags() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.studentTags),
    );

    final data = response.data ?? {};
    final tagsList = (data['tags'] as List?) ?? [];

    return tagsList.map((tag) => tag.toString()).toList();
  }

  @override
  Future<String> getReportDownloadUrl(String assetCode) async {
    AppLogger.d('Resolving asset code to get download URL: $assetCode');

    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.documentMediaAssetsResolve),
      data: {
        'assetCodes': [assetCode],
      },
    );

    final responseData = response.data ?? {};
    final assets = responseData['data']?['assets'] as List?;

    if (assets == null || assets.isEmpty) {
      throw Exception('Asset not found or resolve failed');
    }

    final asset = assets[0] as Map<String, dynamic>;
    var downloadUrl = _extractAssetDownloadUrl(asset);

    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw Exception('No download URL found in resolved asset');
    }

    // Replace template variable if present (fallback for originalDownloadUrl)
    if (downloadUrl.contains('\${DOCUMENT_PUBLIC_BASE_URL}')) {
      final baseUrl = _dio.options.baseUrl;
      downloadUrl = downloadUrl.replaceAll(
        '\${DOCUMENT_PUBLIC_BASE_URL}',
        baseUrl,
      );
      AppLogger.d('Replaced DOCUMENT_PUBLIC_BASE_URL template with: $baseUrl');
    }

    downloadUrl = _sanitizeDownloadUrlHost(downloadUrl);

    AppLogger.d('Asset resolved successfully, download URL obtained: $downloadUrl');
    return downloadUrl;
  }

  /// Pulls the downloadable URL out of a resolved media-asset.
  ///
  /// Some assets carry the URL directly (`deliveryUrl`/`originalDownloadUrl`),
  /// but report assets only get a URL once a processed artifact exists —
  /// that lives under `variants[]` (e.g. `artifactUrl` on the
  /// `defaultVariant: true` entry), not on the asset itself.
  String? _extractAssetDownloadUrl(Map<String, dynamic> asset) {
    String pickFromMap(Map<dynamic, dynamic> map) {
      final candidates = <dynamic>[
        map['deliveryUrl'],
        map['artifactUrl'],
        map['url'],
        map['originalDownloadUrl'],
      ];
      for (final raw in candidates) {
        final value = (raw ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final direct = pickFromMap(asset);
    if (direct.isNotEmpty) return direct;

    final variants = asset['variants'];
    if (variants is List) {
      for (final row in variants.whereType<Map>()) {
        final isDefault =
            (row['defaultVariant'] ?? false).toString().toLowerCase() ==
                'true';
        if (!isDefault) continue;
        final fromDefault = pickFromMap(row);
        if (fromDefault.isNotEmpty) return fromDefault;
      }
      for (final row in variants.whereType<Map>()) {
        final any = pickFromMap(row);
        if (any.isNotEmpty) return any;
      }
    }
    return null;
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

    final isLoopback = uri.host.isEmpty ||
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1';
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

  @override
  Future<List<int>> downloadReportFile(String downloadUrl) async {
    AppLogger.d('Downloading report file from URL');

    final response = await _dio.get<List<int>>(
      downloadUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) {
      throw Exception('Failed to download report: No data received');
    }

    AppLogger.d('Report file downloaded successfully: ${response.data!.length} bytes');
    return response.data!;
  }
}
