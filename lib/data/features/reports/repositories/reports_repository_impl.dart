import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/reports/entities/report_entity.dart';
import '../../../../domain/features/reports/entities/report_metadata_entity.dart';
import '../../../../domain/features/reports/repositories/reports_repository.dart';
import '../../../../domain/features/reports/usecases/report_params.dart';
import '../datasources/reports_remote_datasource.dart';
import '../models/recent_report_model.dart';
import '../models/report_response_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._remoteDataSource, StorageService storageService)
    : _cacheManager = CacheManager(storageService),
      _storageService = storageService;

  final ReportsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;
  final StorageService _storageService;

  // Cache duration: 30 minutes for recent reports
  static const Duration _recentReportsCacheDuration = Duration(minutes: 30);

  // Cache duration: 30 minutes for tags
  static const Duration _tagsCacheDuration = Duration(minutes: 30);

  /// Build cache key for recent reports by type.
  static String _buildRecentReportsCacheKey(String reportSourceType) {
    return CacheManager.buildCacheKey(
      feature: 'reports',
      resource: 'recent',
      identifier: reportSourceType,
    );
  }

  /// Build cache key for tags.
  static String _buildTagsCacheKey() {
    return CacheManager.buildCacheKey(
      feature: 'reports',
      resource: 'tags',
      identifier: 'school',
    );
  }

  @override
  Future<ReportEntity> generateReport(ReportParams params) async {
    AppLogger.d('[REPORTS-REPO] generateReport called: ${params.reportType.backendValue}');

    // Build request body with required fields
    var requestBody = params.toRequestBody();

    // Add required fields from storage to all report payloads
    final schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    final organizationCode = await _storageService.getString(StorageKeys.organizationCode) ?? '';
    final userCode = await _storageService.getString(StorageKeys.userCode) ?? '';

    requestBody['schoolCode'] = schoolCode;
    requestBody['organizationCode'] = organizationCode;
    requestBody['generatedBy'] = userCode;

    AppLogger.d('[REPORTS-REPO] Calling remote datasource for fresh API call');

    // Always make fresh API call - no caching of generated reports
    final response = await _remoteDataSource.generateReport(
      reportType: params.reportType.backendValue,
      requestBody: requestBody,
    );

    AppLogger.i('[REPORTS-REPO] API response received: ID=${response.reportId}, File=${response.fileName}');

    return _mapResponseModelToEntity(response);
  }

  @override
  Future<List<ReportMetadataEntity>> getRecentReports() async {
    AppLogger.d('[REPORTS] Repository: Starting getRecentReports()');

    // Fetch from all 4 sources in parallel with eagerError: false
    // so that if some fail, we still get results from successful ones
    final results = await Future.wait<List<RecentReportModel>>(
      [
        _getRecentWithCache('student_attendance'),
        _getRecentWithCache('staff_attendance'),
        _getRecentWithCache('staff'),
        _getRecentWithCache('student_management'),
      ],
      eagerError: false,
    );

    AppLogger.d('[REPORTS] Student Attendance Reports Count: ${results[0].length}');
    AppLogger.d('[REPORTS] Staff Attendance Reports Count: ${results[1].length}');
    AppLogger.d('[REPORTS] Staff Reports Count: ${results[2].length}');
    AppLogger.d('[REPORTS] Student Management Reports Count: ${results[3].length}');

    // Flatten all results
    final allReports = results.expand((x) => x).toList();
    AppLogger.d('[REPORTS] Total Merged Reports Count: ${allReports.length}');

    // Deduplicate by reportId (keep last occurrence)
    final unique = <String, ReportMetadataEntity>{};
    for (final report in allReports) {
      final entity = _mapRecentModelToEntity(report);
      unique[entity.reportId] = entity;
    }

    AppLogger.d('[REPORTS] After dedup: ${unique.length}');

    // Sort by date descending (most recent first)
    final sorted = unique.values.toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

    AppLogger.d('[REPORTS] Final List Length: ${sorted.length}');
    for (final report in sorted.take(5)) {
      AppLogger.d('[REPORTS]   - ${report.fileName} (${report.generatedAt})');
    }

    return sorted;
  }

  /// Get recent reports from a specific source with caching.
  Future<List<RecentReportModel>> _getRecentWithCache(String sourceType) async {
    final cacheKey = _buildRecentReportsCacheKey(sourceType);

    // Check cache first (30-minute validity)
    final cachedPayload = await _cacheManager.loadCache(
      cacheKey,
      validFor: _recentReportsCacheDuration,
    );

    if (cachedPayload != null) {
      final reportsList = (cachedPayload['reports'] as List?) ?? [];
      return reportsList
          .map(
            (item) => RecentReportModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    // Fetch from API based on source type
    final models = switch (sourceType) {
      'student_attendance' =>
        await _remoteDataSource.getRecentStudentAttendanceReports(),
      'staff_attendance' =>
        await _remoteDataSource.getRecentStaffAttendanceReports(),
      'staff' => await _remoteDataSource.getRecentStaffReports(),
      'student_management' =>
        await _remoteDataSource.getRecentStudentManagementReports(),
      _ => <RecentReportModel>[],
    };

    // Cache result
    await _cacheManager.saveCache(cacheKey, {
      'reports': models.map((m) => m.toJson()).toList(),
    });

    return models;
  }

  @override
  Future<List<String>> getStudentTags() async {
    final cacheKey = _buildTagsCacheKey();

    // Check cache first (30-minute validity)
    final cachedPayload = await _cacheManager.loadCache(
      cacheKey,
      validFor: _tagsCacheDuration,
    );

    if (cachedPayload != null) {
      final tagsList = (cachedPayload['tags'] as List?) ?? [];
      return tagsList.map((tag) => tag.toString()).toList();
    }

    // Fetch from API
    final tags = await _remoteDataSource.getStudentTags();

    // Cache result
    await _cacheManager.saveCache(cacheKey, {'tags': tags});

    return tags;
  }

  /// Map ReportResponseModel to ReportEntity.
  ReportEntity _mapResponseModelToEntity(ReportResponseModel model) {
    return model.toEntity();
  }

  /// Map RecentReportModel to ReportMetadataEntity.
  ReportMetadataEntity _mapRecentModelToEntity(RecentReportModel model) {
    return model.toEntity();
  }

  @override
  Future<String> getReportDownloadUrl(String assetCode) async {
    AppLogger.d('Getting download URL for asset: $assetCode');
    return _remoteDataSource.getReportDownloadUrl(assetCode);
  }

  @override
  Future<List<int>> downloadReportFile(String downloadUrl) async {
    AppLogger.d('Downloading report file');
    return _remoteDataSource.downloadReportFile(downloadUrl);
  }
}
