import 'package:dio/dio.dart';
import '../models/report_response_model.dart';
import '../models/recent_report_model.dart';
import 'reports_remote_datasource.dart';

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

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

    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: requestBody,
    );

    return ReportResponseModel.fromJson(response.data ?? {});
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentAttendanceReports() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/attendance/student-attendance/reports/recent',
    );

    final data = response.data ?? {};
    final reportsList = (data['reports'] as List?) ?? [];

    return reportsList
        .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffAttendanceReports() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/attendance/staff-attendance/reports/recent',
    );

    final data = response.data ?? {};
    final reportsList = (data['reports'] as List?) ?? [];

    return reportsList
        .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffReports() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/staff/staff/reports/recent',
    );

    final data = response.data ?? {};
    final reportsList = (data['reports'] as List?) ?? [];

    return reportsList
        .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentManagementReports() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/student/student/reports/recent',
    );

    final data = response.data ?? {};
    final reportsList = (data['reports'] as List?) ?? [];

    return reportsList
        .map((item) => RecentReportModel.fromJson(item as Map<String, dynamic>))
        .toList();
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
}
