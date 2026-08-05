import '../../../../core/errors/failures.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/school_context_helper.dart';
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

  // Cache duration: 30 minutes for tags
  static const Duration _tagsCacheDuration = Duration(minutes: 30);

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
    AppLogger.d(
      '[REPORTS-REPO] generateReport called: ${params.reportType.backendValue}',
    );

    // Build request body with required fields
    var requestBody = params.toRequestBody();

    // Add required fields from storage to all report payloads
    final schoolCode =
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    final organizationCode =
        await _storageService.getString(StorageKeys.organizationCode) ?? '';
    final userCode =
        await _storageService.getString(StorageKeys.userCode) ?? '';
    // Pass the schoolName properly instead of the schoolCode in the schoolName field.
    final schoolName = await SchoolContextHelper.getSchoolName();
    requestBody['schoolCode'] = schoolCode;
    requestBody['organizationCode'] = organizationCode;
    requestBody['generatedBy'] = userCode;
    if (schoolName != null && schoolName.isNotEmpty) {
      requestBody['schoolName'] = schoolName;
    }

    AppLogger.d('[REPORTS-REPO] Calling remote datasource for fresh API call');

    // Always make fresh API call - no caching of generated reports
    final response = await _remoteDataSource.generateReport(
      reportType: params.reportType,
      requestBody: requestBody,
    );

    AppLogger.i(
      '[REPORTS-REPO] API response received: ID=${response.reportId}, File=${response.fileName}',
    );

    return _mapResponseModelToEntity(response);
  }

  /// Resolves the human-readable school name for [schoolCode]/[organizationCode]
  /// from the cached org/school list, since `StorageKeys.selectedSchoolName`
  /// is sometimes populated with the school code instead of its name.
  // Future<String> _resolveSchoolName(
  //   String schoolCode,
  //   String organizationCode,
  // ) async {
  //   final storedName =
  //       await _storageService.getString(StorageKeys.selectedSchoolName) ?? '';

  //   final raw = await _storageService.getString(
  //     StorageKeys.organizationsAndSchools,
  //   );
  //   if (raw != null && raw.isNotEmpty) {
  //     try {
  //       final decoded = jsonDecode(raw);
  //       if (decoded is List) {
  //         final list = decoded.whereType<Map>().map(
  //           (e) => Map<String, dynamic>.from(e),
  //         );
  //         final match = list.firstWhere(
  //           (e) =>
  //               (e['schoolCode']?.toString() ?? '') == schoolCode &&
  //               (e['organizationCode']?.toString() ?? '') == organizationCode,
  //           orElse: () => const <String, dynamic>{},
  //         );
  //         final fromList = match['schoolName']?.toString() ?? '';
  //         if (fromList.isNotEmpty) {
  //           return fromList;
  //         }
  //       }
  //     } catch (e) {
  //       AppLogger.e(
  //         '[REPORTS-REPO] Failed to parse organizationsAndSchools: $e',
  //       );
  //     }
  //   }

  //   // Fallback to stored name or the code itself if no better name is found.
  //   return storedName.isNotEmpty ? storedName : schoolCode;
  // }

  @override
  Future<List<ReportMetadataEntity>> getRecentReports() async {
    AppLogger.d('[REPORTS] Repository: Starting getRecentReports()');

    // Note: billing and IMMUNIZATION reports have no "recent" endpoint
    // (ApiPaths has no billing/immunization-recent route), so they are
    // intentionally absent from this list, not silently dropped by a bug.
    final sources = <_RecentReportsSource>[
      _RecentReportsSource(
        'Student Attendance',
        _remoteDataSource.getRecentStudentAttendanceReports,
      ),
      _RecentReportsSource(
        'Staff Attendance',
        _remoteDataSource.getRecentStaffAttendanceReports,
      ),
      _RecentReportsSource(
        'Staff Reports',
        _remoteDataSource.getRecentStaffReports,
      ),
      _RecentReportsSource(
        'Student Management',
        _remoteDataSource.getRecentStudentManagementReports,
      ),
    ];

    // Fetch each source independently so one failing source doesn't discard
    // results from sources that succeeded — but unlike before, a failure is
    // logged AND recorded, not silently turned into an empty list.
    final results = await Future.wait(sources.map(_safeFetchRecent));

    final allReports = <RecentReportModel>[];
    final failures = <String>[];
    for (final result in results) {
      if (result.error != null) {
        failures.add('${result.label}: ${result.error}');
      } else {
        AppLogger.d(
          '[REPORTS] ${result.label} Reports Count: ${result.data.length}',
        );
        allReports.addAll(result.data);
      }
    }

    if (allReports.isEmpty && failures.isNotEmpty) {
      // Every source failed: surface a real Failure instead of "0 reports".
      throw ServerFailure(
        'Failed to load recent reports: ${failures.join('; ')}',
      );
    }
    if (failures.isNotEmpty) {
      AppLogger.e(
        '[REPORTS] Some recent-report sources failed: ${failures.join('; ')}',
      );
    }

    AppLogger.d('[REPORTS] Total Merged Reports Count: ${allReports.length}');

    // Deduplicate by reportId (keep last occurrence). A single unparseable
    // entry is skipped (and logged) rather than failing the whole list.
    final unique = <String, ReportMetadataEntity>{};
    for (final model in allReports) {
      try {
        final entity = _mapRecentModelToEntity(model);
        unique[entity.reportId] = entity;
      } catch (e) {
        AppLogger.w(
          '[REPORTS] Skipping unparseable recent report (${model.reportId}): $e',
        );
      }
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

  Future<_RecentFetchResult> _safeFetchRecent(
    _RecentReportsSource source,
  ) async {
    try {
      final data = await source.fetch();
      return _RecentFetchResult(label: source.label, data: data);
    } catch (e) {
      AppLogger.e('[REPORTS] ${source.label} recent-reports fetch failed: $e');
      return _RecentFetchResult(label: source.label, data: const [], error: e);
    }
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

/// One named "recent reports" data source, paired with a label used for
/// logging/error aggregation in [ReportsRepositoryImpl._safeFetchRecent].
class _RecentReportsSource {
  _RecentReportsSource(this.label, this.fetch);

  final String label;
  final Future<List<RecentReportModel>> Function() fetch;
}

/// Outcome of fetching one [_RecentReportsSource]: either [data] (success)
/// or [error] (failure) — never both, never silently neither.
class _RecentFetchResult {
  _RecentFetchResult({required this.label, required this.data, this.error});

  final String label;
  final List<RecentReportModel> data;
  final Object? error;
}
