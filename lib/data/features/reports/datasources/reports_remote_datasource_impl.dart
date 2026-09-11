import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart' as storage_keys;
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/data/features/reports/models/report_response_model.dart';
import 'package:wowcare/data/features/reports/models/report_generation_envelope.dart';
import 'package:wowcare/data/features/reports/models/recent_report_model.dart';
import 'package:wowcare/data/features/reports/models/recent_reports_response.dart';
import 'package:wowcare/data/features/reports/models/student_tags_response.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'report_asset_source.dart';
import 'reports_remote_datasource.dart';

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl(this._dio, this._storageService)
    : _assets = ReportAssetSource(_dio);

  final Dio _dio;
  final StorageService _storageService;

  /// Asset-code resolution and file download, which talk to the media service
  /// rather than the reports API.
  final ReportAssetSource _assets;

  @override
  Future<String> getReportDownloadUrl(String assetCode) =>
      _assets.getReportDownloadUrl(assetCode);

  @override
  Future<List<int>> downloadReportFile(String downloadUrl) =>
      _assets.downloadReportFile(downloadUrl);

  @override
  Future<ReportResponseModel> generateReport({
    required ReportType reportType,
    required ReportRequestPayload payload,
  }) async {
    // The one and only place a report request becomes a map.
    final requestBody = payload.toJson();
    final endpoint = _generateEndpointFor(reportType);
    final headers = Map<String, dynamic>.from(_dio.options.headers);

    AppLogger.d('========== REPORT REQUEST ==========');
    AppLogger.d('Endpoint: ${ApiPaths.url(endpoint)}');
    AppLogger.d('Headers: $headers');
    AppLogger.d('Payload: $requestBody');
    AppLogger.d('====================================');
    _logPayloadFieldTypes(requestBody);

    try {
      Response<Map<String, dynamic>> response;
      if (reportType == ReportType.billingTransaction ||
          reportType == ReportType.billingInvoice ||
          reportType == ReportType.billingPaymentSummary ||
          reportType == ReportType.billingOutstanding ||
          reportType == ReportType.billingRefund ||
          reportType == ReportType.billingStudentMapping) {
        final schoolCode = await _storageService.getString(
          storage_keys.StorageKeys.schoolCode,
        );
        final organizationCode = await _storageService.getString(
          storage_keys.StorageKeys.organizationCode,
        );

        final queryParams = Map<String, dynamic>.from(requestBody);
        if (schoolCode != null && schoolCode.trim().isNotEmpty) {
          queryParams['schoolCode'] = schoolCode.trim();
          queryParams['schoolId'] = schoolCode.trim();
        }
        if (organizationCode != null && organizationCode.trim().isNotEmpty) {
          queryParams['organizationCode'] = organizationCode.trim();
          queryParams['orgId'] = organizationCode.trim();
        }

        final rawResponse = await _dio.get<List<int>>(
          ApiPaths.url(endpoint),
          queryParameters: queryParams,
          options: Options(
            responseType: ResponseType.bytes,
            validateStatus: (status) => true,
          ),
        );
        if (rawResponse.statusCode == 200) {
          final base64Data = base64Encode(rawResponse.data!);
          return ReportResponseModel(
            reportId: 'sync-${DateTime.now().millisecondsSinceEpoch}',
            reportType: reportType.backendValue,
            generatedAt: DateTime.now().toIso8601String(),
            assetCode: 'base64:$base64Data',
            fileName: '${reportType.backendValue}_report.xlsx',
          );
        } else {
          final envelope = ReportGenerationEnvelope.fromJson(
            jsonDecode(utf8.decode(rawResponse.data!)) as Map<String, dynamic>,
          );
          throw FormatException(
            'Report generation failed: ${envelope.message ?? 'unknown error'}',
          );
        }
      } else {
        response = await _dio.post<Map<String, dynamic>>(
          ApiPaths.url(endpoint),
          data: requestBody,
        );
      }
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
        return ApiPaths.billingTransactionReportGenerate;
      case ReportType.billingInvoice:
        return ApiPaths.billingInvoiceReportGenerate;
      case ReportType.billingPaymentSummary:
        return ApiPaths.billingPaymentSummaryReportGenerate;
      case ReportType.billingOutstanding:
        return ApiPaths.billingOutstandingReportGenerate;
      case ReportType.billingRefund:
        return ApiPaths.billingRefundReportGenerate;
      case ReportType.billingStudentMapping:
        return ApiPaths.billingStudentMappingReportGenerate;
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

    // The envelope decides which of the three observed shapes this is; the
    // datasource does not read keys off the map itself (§8).
    final reports = RecentReportsResponse.fromJson(data).toModels();

    AppLogger.d('[REPORTS] $label Reports Count: ${reports.length}');
    return reports;
  }

  @override
  Future<List<String>> getStudentTags() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.studentTags),
    );

    return StudentTagsResponse.fromJson(response.data ?? const {}).names;
  }
}
