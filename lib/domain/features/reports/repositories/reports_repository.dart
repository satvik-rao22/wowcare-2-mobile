import '../entities/report_entity.dart';
import '../entities/report_metadata_entity.dart';
import '../usecases/report_params.dart';

abstract class ReportsRepository {
  /// Generate a report based on request params.
  /// Returns the generated report entity or throws an exception.
  Future<ReportEntity> generateReport(ReportParams params);

  /// Get recent reports merged from all sources (student attendance, staff attendance, staff, student management).
  /// Uses cache-first strategy with 30-minute expiration.
  Future<List<ReportMetadataEntity>> getRecentReports();

  /// Get student tags for dynamic filtering.
  /// Uses cache-first strategy with 30-minute expiration.
  Future<List<String>> getStudentTags();

  /// Get download URL for a report by asset code.
  Future<String> getReportDownloadUrl(String assetCode);

  /// Download a report file from URL.
  Future<List<int>> downloadReportFile(String downloadUrl);
}
