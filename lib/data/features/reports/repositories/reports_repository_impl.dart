import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
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

  // Cache duration: 30 minutes for generated reports
  static const Duration _generatedReportCacheDuration = Duration(minutes: 30);

  // Cache duration: 30 minutes for recent reports
  static const Duration _recentReportsCacheDuration = Duration(minutes: 30);

  // Cache duration: 30 minutes for tags
  static const Duration _tagsCacheDuration = Duration(minutes: 30);

  /// Build cache key for generated reports following standard pattern.
  static String _buildGeneratedReportCacheKey(ReportParams params) {
    return CacheManager.buildCacheKey(
      feature: 'reports',
      resource: 'generated',
      identifier: params.toCacheIdentifier(),
    );
  }

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
    final cacheKey = _buildGeneratedReportCacheKey(params);

    // Check cache first (30-minute validity)
    final cachedPayload = await _cacheManager.loadCache(
      cacheKey,
      validFor: _generatedReportCacheDuration,
    );

    if (cachedPayload != null) {
      final model = ReportResponseModel.fromJson(cachedPayload);
      return _mapResponseModelToEntity(model);
    }

    // Fetch from API
    var requestBody = params.toRequestBody();

    // Add required fields from storage to all report payloads
    final schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    final organizationCode = await _storageService.getString(StorageKeys.organizationCode) ?? '';
    final userCode = await _storageService.getString(StorageKeys.userCode) ?? '';

    requestBody['schoolCode'] = schoolCode;
    requestBody['organizationCode'] = organizationCode;
    requestBody['generatedBy'] = userCode;

    final response = await _remoteDataSource.generateReport(
      reportType: params.reportType.backendValue,
      requestBody: requestBody,
    );

    // Cache result
    await _cacheManager.saveCache(cacheKey, response.toJson());

    return _mapResponseModelToEntity(response);
  }

  @override
  Future<List<ReportMetadataEntity>> getRecentReports() async {
    // Fetch from all 4 sources in parallel
    final results = await Future.wait<List<RecentReportModel>>([
      _getRecentWithCache('student_attendance'),
      _getRecentWithCache('staff_attendance'),
      _getRecentWithCache('staff'),
      _getRecentWithCache('student_management'),
    ]);

    // Flatten all results
    final allReports = results.expand((x) => x).toList();

    // Deduplicate by reportId (keep last occurrence)
    final unique = <String, ReportMetadataEntity>{};
    for (final report in allReports) {
      final entity = _mapRecentModelToEntity(report);
      unique[entity.reportId] = entity;
    }

    // Sort by date descending (most recent first)
    final sorted = unique.values.toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

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
}
