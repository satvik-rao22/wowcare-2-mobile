import 'package:dio/dio.dart';
import '../../../../core/storage/storage_service.dart';
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

    if (reportType.startsWith('STUDENT_')) {
      // Student attendance reports
      endpoint = '/api/v1/attendance/student-attendance/reports/generate';
    } else if (reportType.startsWith('STAFF_')) {
      if (reportType == 'STAFF_DETAILS') {
        // Staff directory
        endpoint = '/api/v1/staff/staff/reports/generate';
      } else {
        // Staff attendance reports
        endpoint = '/api/v1/attendance/staff-attendance/reports/generate';
      }
    } else if (reportType == 'STUDENTS_AND_FAMILY' ||
        reportType == 'EMERGENCY_CONTACTS') {
      // Student management reports
      endpoint = '/api/v1/student/student/reports/generate';
    } else if (reportType == 'IMMUNIZATION') {
      // Immunization report
      endpoint = '/api/v1/student/settings/immunization/report';
    } else {
      throw ArgumentError('Unknown report type: $reportType');
    }

    AppLogger.d('Posting to $endpoint with payload: $requestBody');
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
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
    final endpoint = '/api/v1/attendance/student-attendance/reports/recent';
    AppLogger.d('[REPORTS] Student Attendance API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
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
    final endpoint = '/api/v1/attendance/staff-attendance/reports/recent';
    AppLogger.d('[REPORTS] Staff Attendance API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
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
    final endpoint = '/api/v1/staff/staff/reports/recent';
    AppLogger.d('[REPORTS] Staff Reports API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
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
    final endpoint = '/api/v1/student/student/reports/recent';
    AppLogger.d('[REPORTS] Student Management API: Loading with schoolCode=$schoolCode');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
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
      '/api/v1/student/tags',
    );

    final data = response.data ?? {};
    final tagsList = (data['tags'] as List?) ?? [];

    return tagsList.map((tag) => tag.toString()).toList();
  }

  @override
  Future<String> getReportDownloadUrl(String assetCode) async {
    AppLogger.d('Resolving asset code to get download URL: $assetCode');

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/document/media-assets/resolve',
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
    // Prefer deliveryUrl (direct CDN) over originalDownloadUrl (template/API endpoint)
    var downloadUrl = asset['deliveryUrl'] ?? asset['originalDownloadUrl'];

    if (downloadUrl == null) {
      throw Exception('No download URL found in resolved asset');
    }

    downloadUrl = downloadUrl as String;

    // Replace template variable if present (fallback for originalDownloadUrl)
    if (downloadUrl.contains('\${DOCUMENT_PUBLIC_BASE_URL}')) {
      final baseUrl = _dio.options.baseUrl;
      downloadUrl = downloadUrl.replaceAll(
        '\${DOCUMENT_PUBLIC_BASE_URL}',
        baseUrl,
      );
      AppLogger.d('Replaced DOCUMENT_PUBLIC_BASE_URL template with: $baseUrl');
    }

    AppLogger.d('Asset resolved successfully, download URL obtained: $downloadUrl');
    return downloadUrl;
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
