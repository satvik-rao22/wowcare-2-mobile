import 'package:dio/dio.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/storage_keys.dart' as storage_keys;
import '../../../../domain/features/reports/entities/report_type.dart';
import '../models/report_response_model.dart';
import '../models/recent_report_model.dart';
import 'reports_remote_datasource.dart';

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl(this._dio, this._storageService);

  final Dio _dio;
  final StorageService _storageService;

  @override
  Future<ReportResponseModel> generateReport({
    required ReportType reportType,
    required Map<String, dynamic> requestBody,
  }) async {
    final endpoint = _generateEndpointFor(reportType);
    final headers = Map<String, dynamic>.from(_dio.options.headers);

    AppLogger.d('========== REPORT REQUEST ==========');
    AppLogger.d('Endpoint: ${ApiPaths.url(endpoint)}');
    AppLogger.d('Headers: $headers');
    AppLogger.d('Payload: $requestBody');
    AppLogger.d('====================================');
    _logPayloadFieldTypes(requestBody);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.url(endpoint),
        data: requestBody,
      );
      final responseData = response.data ?? {};

      AppLogger.d('========== REPORT RESPONSE ==========');
      AppLogger.d('Endpoint: ${ApiPaths.url(endpoint)}');
      AppLogger.d('Status Code: ${response.statusCode}');
      AppLogger.d('Response Body: $responseData');
      AppLogger.d('=====================================');

      return ReportResponseModel.fromJson(responseData);
    } catch (error, stackTrace) {
      AppLogger.e('========== REPORT ERROR ==========', error, stackTrace);
      AppLogger.e('Endpoint: ${ApiPaths.url(endpoint)}');
      AppLogger.e('Request Headers: $headers');
      AppLogger.e('Request Payload: $requestBody');
      if (error is DioException) {
        AppLogger.e('DioException type: ${error.type}');
        AppLogger.e('DioException response: ${error.response?.data}');
        AppLogger.e('DioException statusCode: ${error.response?.statusCode}');
      }
      AppLogger.e('=====================================');
      rethrow;
    }
  }

  /// Logs the runtime type of every collection-shaped field in the outgoing
  /// payload. Catches exactly the class of bug that caused statusFilter to
  /// be serialized as a String instead of a List<String> — that mistake is
  /// invisible in a plain payload dump (both print as a quoted value) but
  /// immediately obvious once the runtime type is logged alongside it.
  void _logPayloadFieldTypes(Map<String, dynamic> requestBody) {
    const collectionFields = [
      'roomCodes',
      'classroomCodes',
      'tagCodes',
      'statusFilter',
      'studentCodes',
      'staffCodes',
      'vaccineCodes',
    ];
    for (final field in collectionFields) {
      if (!requestBody.containsKey(field)) continue;
      final value = requestBody[field];
      final isList = value is List;
      AppLogger.d(
        '[REPORTS] payload.$field = $value (runtime type: ${value.runtimeType}'
        '${isList ? '' : ' — WARNING: expected a List'})',
      );
    }
  }

  /// Exhaustive mapping from [ReportType] to its generate endpoint.
  ///
  /// A `switch` over the enum (not string `startsWith`/`contains` matching)
  /// so the analyzer raises a compile-time error if a new [ReportType] case
  /// is added without a matching endpoint here — no runtime
  /// `ArgumentError("Unknown report type")` is reachable.
  String _generateEndpointFor(ReportType reportType) {
    switch (reportType) {
      case ReportType.studentDailyAttendance:
      case ReportType.studentAbsent:
      case ReportType.studentAttendancePerStudent:
        return ApiPaths.studentAttendanceReportsGenerate;
      case ReportType.staffAbsent:
      case ReportType.staffAttendance:
      case ReportType.staffAttendancePerStaff:
        return ApiPaths.staffAttendanceReportsGenerate;
      case ReportType.staffScheduling:
        return ApiPaths.staffSchedulingReportsGenerate;
      case ReportType.staffDetails:
        return ApiPaths.staffReportsGenerate;
      case ReportType.studentsAndFamily:
      case ReportType.emergencyContacts:
      case ReportType.annualStateImmunization:
        return ApiPaths.studentManagementReportsGenerate;
      case ReportType.studentIncident:
        return ApiPaths.studentIncidentReportsGenerate;
      case ReportType.immunization:
        // TODO(backend-confirm): unverified whether this dedicated route is
        // still live, or whether immunization now goes through
        // ApiPaths.studentManagementReportsGenerate with
        // reportType=IMMUNIZATION. Do not change without a captured
        // request/response pair from the live backend — flipping this
        // blind risks breaking a currently-working report.
        return ApiPaths.studentImmunizationReport;
      case ReportType.billingTransaction:
      case ReportType.billingInvoice:
      case ReportType.billingPaymentSummary:
      case ReportType.billingOutstanding:
      case ReportType.billingRefund:
      case ReportType.billingStudentMapping:
        return ApiPaths.billingReportGenerate;
    }
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentAttendanceReports() {
    return _fetchRecentReports(
      label: 'Student Attendance',
      endpoint: ApiPaths.studentAttendanceReportsRecent,
    );
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffAttendanceReports() {
    return _fetchRecentReports(
      label: 'Staff Attendance',
      endpoint: ApiPaths.staffAttendanceReportsRecent,
    );
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffReports() {
    return _fetchRecentReports(
      label: 'Staff Reports',
      endpoint: ApiPaths.staffReportsRecent,
    );
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentManagementReports() {
    return _fetchRecentReports(
      label: 'Student Management',
      endpoint: ApiPaths.studentManagementReportsRecent,
    );
  }

  /// Shared GET + parse for all "recent reports" endpoints.
  ///
  /// Does NOT catch errors — DioException/parse failures propagate to the
  /// caller so they can be surfaced as a [Failure] instead of being hidden
  /// behind an empty list (see `ReportsRepositoryImpl.getRecentReports`,
  /// which wraps each source individually and logs/aggregates failures
  /// without losing results from sources that did succeed).
  Future<List<RecentReportModel>> _fetchRecentReports({
    required String label,
    required String endpoint,
  }) async {
    final schoolCode = await _storageService.getString(
      storage_keys.StorageKeys.schoolCode,
    );
    AppLogger.d('[REPORTS] $label API: Loading with schoolCode=$schoolCode');

    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.url(endpoint),
      queryParameters: {'schoolCode': schoolCode},
    );

    final data = response.data ?? {};
    AppLogger.d(
      '[REPORTS] $label API: Raw response keys=${data.keys.toList()}',
    );

    // The backend's envelope shape for this family of endpoints hasn't been
    // confirmed (see audit), so we still try the three observed shapes
    // rather than assuming one — but unlike before, finding none of them
    // returns an empty list normally (not via a swallowed exception).
    List? reportsList = data['reports'] as List?;
    final dataField = data['data'];
    if (reportsList == null && dataField is List) {
      reportsList = dataField;
    } else if (reportsList == null && dataField is Map) {
      reportsList = dataField['reports'] as List?;
    }

    AppLogger.d('[REPORTS] $label Reports Count: ${reportsList?.length ?? 0}');
    if (reportsList == null) return const [];

    return reportsList
        .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
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

    AppLogger.d(
      'Asset resolved successfully, download URL obtained: $downloadUrl',
    );
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
            (row['defaultVariant'] ?? false).toString().toLowerCase() == 'true';
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

    AppLogger.d(
      'Report file downloaded successfully: ${response.data!.length} bytes',
    );
    return response.data!;
  }
}
