import '../../../../../domain/features/reports/usecases/report_request_params.dart';
import '../models/report_response_model.dart';
import '../models/recent_report_model.dart';

/// Remote data source interface for reports API calls.
///
/// Handles all HTTP requests to report endpoints.
/// Returns models (not entities) for flexibility.
abstract class ReportsRemoteDataSource {
  /// Generate a report by type and filters.
  ///
  /// POST request to:
  /// - `/api/v1/attendance/student-attendance/reports/generate` (student attendance)
  /// - `/api/v1/attendance/staff-attendance/reports/generate` (staff attendance)
  /// - `/api/v1/staff/staff/reports/generate` (staff directory)
  /// - `/api/v1/student/student/reports/generate` (student management)
  /// - `/api/v1/student/settings/immunization/report` (immunization)
  ///
  /// Throws DioException on network/server errors.
  Future<ReportResponseModel> generateReport({
    required String reportType,
    required Map<String, dynamic> requestBody,
  });

  /// Get recent student attendance reports.
  /// GET `/api/v1/attendance/student-attendance/reports/recent`
  Future<List<RecentReportModel>> getRecentStudentAttendanceReports();

  /// Get recent staff attendance reports.
  /// GET `/api/v1/attendance/staff-attendance/reports/recent`
  Future<List<RecentReportModel>> getRecentStaffAttendanceReports();

  /// Get recent staff reports.
  /// GET `/api/v1/staff/staff/reports/recent`
  Future<List<RecentReportModel>> getRecentStaffReports();

  /// Get recent student management reports.
  /// GET `/api/v1/student/student/reports/recent`
  Future<List<RecentReportModel>> getRecentStudentManagementReports();

  /// Get student tags for filtering.
  /// GET `/api/v1/student/tags`
  Future<List<String>> getStudentTags();

  /// Resolve asset code to get download URL.
  /// POST `/api/v1/document/media-assets/resolve`
  Future<String> getReportDownloadUrl(String assetCode);

  /// Download a report file from URL.
  /// GET request to the download URL
  Future<List<int>> downloadReportFile(String downloadUrl);

  /// Stream a billing report's bytes directly from the accounts MS (fallback when the
  /// document service didn't return an asset). GET /api/v1/reports/billing/{reportType}.
  Future<List<int>> downloadBillingReportBytes(ReportRequestParams params);
}
