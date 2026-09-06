import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/data/features/reports/models/report_response_model.dart';
import 'package:wowcare/data/features/reports/models/recent_report_model.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';

/// Remote data source interface for reports API calls.
///
/// Handles all HTTP requests to report endpoints.
/// Returns models (not entities) for flexibility.
abstract class ReportsRemoteDataSource {
  /// Generate a report by type and filters.
  ///
  /// The endpoint is resolved from [reportType] via an exhaustive switch in
  /// the implementation (see `ReportsRemoteDataSourceImpl._generateEndpointFor`),
  /// not string matching — current mapping:
  /// - `/api/v1/attendance/student-attendance/reports/generate` (student attendance)
  /// - `/api/v1/attendance/staff-attendance/reports/generate` (staff attendance)
  /// - `/api/v1/staff/reports/generate` (staff directory)
  /// - `/api/v1/student/reports/generate` (student management)
  /// - `/api/v1/student/settings/immunization/report` (immunization — UNCONFIRMED,
  ///   see TODO at the switch case; some reports of this being replaced by
  ///   `/api/v1/student/reports/generate` with `reportType=IMMUNIZATION` are
  ///   unverified against the live backend)
  /// - `/api/v1/reports/billing/generate` (billing)
  ///
  /// Throws DioException on network/server errors, FormatException if the
  /// backend response doesn't match the expected contract.
  /// [payload] is the typed request body; `toJson()` is called here, at the
  /// edge, and nowhere further in (§8).
  Future<ReportResponseModel> generateReport({
    required ReportType reportType,
    required ReportRequestPayload payload,
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
}
