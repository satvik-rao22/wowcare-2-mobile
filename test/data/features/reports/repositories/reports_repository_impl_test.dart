import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/reports/datasources/reports_remote_datasource.dart';
import 'package:wowcare/data/features/reports/models/recent_report_model.dart';
import 'package:wowcare/data/features/reports/models/report_response_model.dart';
import 'package:wowcare/data/features/reports/repositories/reports_repository_impl.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<List<Map<String, String>>> getOrganizationsAndSchools() async => [];

  @override
  Future<Map<String, dynamic>?> getLoginContext() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemoteDataSource extends Fake implements ReportsRemoteDataSource {
  bool shouldThrow = false;
  late Future<ReportResponseModel> Function() generateReportResponse;
  late Future<List<RecentReportModel>> Function()
  recentStudentAttendanceResponse;
  late Future<List<RecentReportModel>> Function() recentStaffAttendanceResponse;
  late Future<List<RecentReportModel>> Function() recentStaffResponse;
  late Future<List<RecentReportModel>> Function()
  recentStudentManagementResponse;
  late Future<List<String>> Function() tagsResponse;

  /// The payload the repository handed over on the last generate call.
  ReportRequestPayload? lastPayload;

  @override
  Future<ReportResponseModel> generateReport({
    required ReportType reportType,
    required ReportRequestPayload payload,
  }) async {
    lastPayload = payload;
    if (shouldThrow) throw Exception('API Error');
    return generateReportResponse();
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentAttendanceReports() async {
    if (shouldThrow) throw Exception('API Error');
    return recentStudentAttendanceResponse();
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffAttendanceReports() async {
    if (shouldThrow) throw Exception('API Error');
    return recentStaffAttendanceResponse();
  }

  @override
  Future<List<RecentReportModel>> getRecentStaffReports() async {
    if (shouldThrow) throw Exception('API Error');
    return recentStaffResponse();
  }

  @override
  Future<List<RecentReportModel>> getRecentStudentManagementReports() async {
    if (shouldThrow) throw Exception('API Error');
    return recentStudentManagementResponse();
  }

  @override
  Future<List<String>> getStudentTags() async {
    if (shouldThrow) throw Exception('API Error');
    return tagsResponse();
  }
}

class FakeStorageService extends Fake implements StorageService {
  final Map<String, dynamic> _storage = {};

  @override
  Future<String?> getString(String key) async => _storage[key] as String?;

  @override
  Future<void> saveString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<int?> getInt(String key) async => _storage[key] as int?;

  @override
  Future<void> saveInt(String key, int value) async {
    _storage[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => _storage[key] as bool?;

  @override
  Future<void> saveBool(String key, bool value) async {
    _storage[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      _storage[key] as Map<String, dynamic>?;

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<Set<String>> getKeys() async => _storage.keys.toSet();

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  void clearStorage() => _storage.clear();
}

void main() {
  late FakeRemoteDataSource fakeDataSource;
  late FakeStorageService fakeStorageService;
  late ReportsRepositoryImpl repository;

  setUp(() async {
    await serviceLocator.reset();
    fakeDataSource = FakeRemoteDataSource();
    fakeStorageService = FakeStorageService();
    serviceLocator.registerSingleton<StorageService>(fakeStorageService);
    serviceLocator.registerSingleton<AuthLocalDataSource>(
      _FakeAuthLocalDataSource(),
    );
    // The repository only reaches for the ApiClient on the cold timezone
    // path; these tests leave the storage cache empty, so the lookup fails
    // fast and the `schoolTimeZone` key is simply omitted.
    repository = ReportsRepositoryImpl(
      fakeDataSource,
      fakeStorageService,
      ApiClient(baseUrl: 'https://example.invalid'),
    );
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  group('ReportsRepositoryImpl', () {
    group('generateReport', () {
      test('returns report entity from API', () async {
        fakeDataSource.generateReportResponse = () async => ReportResponseModel(
          reportId: 'report-123',
          reportType: 'STUDENT_DAILY_ATTENDANCE',
          generatedAt: '2026-01-15T10:30:00Z',
          assetCode: 'asset-456',
          fileName: 'report.xlsx',
        );

        final params = ReportRequestParams(
          reportType: ReportType.studentDailyAttendance,
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 15),
          schoolName: 'Dummy School',
        );

        final result = await repository.generateReport(params);

        expect(result.reportId, 'report-123');
        expect(result.reportType, ReportType.studentDailyAttendance);
        expect(result.assetCode, 'asset-456');
        expect(result.fileName, 'report.xlsx');
      });

      test('does not cache report and calls API on second call', () async {
        var apiCallCount = 0;
        fakeDataSource.generateReportResponse = () async {
          apiCallCount++;
          return ReportResponseModel(
            reportId: 'report-123',
            reportType: 'STUDENT_DAILY_ATTENDANCE',
            generatedAt: '2026-01-15T10:30:00Z',
          );
        };

        final params = ReportRequestParams(
          reportType: ReportType.studentDailyAttendance,
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 15),
          schoolName: 'Dummy School',
        );

        // First call - API
        await repository.generateReport(params);
        expect(apiCallCount, 1);

        // Second call - should also call API (no cache)
        await repository.generateReport(params);
        expect(apiCallCount, 2);
      });

      test('propagates API errors', () async {
        fakeDataSource.shouldThrow = true;

        final params = ReportRequestParams(
          reportType: ReportType.studentDailyAttendance,
          startDate: DateTime(2026, 1, 15),

          schoolName: 'Dummy School',
          endDate: DateTime(2026, 1, 15),
        );

        expect(() => repository.generateReport(params), throwsException);
      });

      test('uses different cache keys for different report types', () async {
        var apiCallCount = 0;
        fakeDataSource.generateReportResponse = () async {
          apiCallCount++;
          return ReportResponseModel(
            reportId: 'report-$apiCallCount',
            reportType: 'STUDENT_DAILY_ATTENDANCE',
            generatedAt: '2026-01-15T10:30:00Z',
          );
        };

        final params1 = ReportRequestParams(
          reportType: ReportType.studentDailyAttendance,
          startDate: DateTime(2026, 1, 15),
          schoolName: 'Dummy School',
          endDate: DateTime(2026, 1, 15),
        );

        final params2 = ReportRequestParams(
          reportType: ReportType.studentAbsent,
          startDate: DateTime(2026, 1, 15),
          schoolName: 'Dummy School',
          endDate: DateTime(2026, 1, 15),
        );

        await repository.generateReport(params1);
        await repository.generateReport(params2);

        // Both should call API since they have different cache keys
        expect(apiCallCount, 2);
      });
    });

    group('getRecentReports', () {
      test('fetches from all 4 sources in parallel', () async {
        var studentAttendanceCallCount = 0;
        var staffAttendanceCallCount = 0;
        var staffCallCount = 0;
        var studentMgmtCallCount = 0;

        fakeDataSource.recentStudentAttendanceResponse = () async {
          studentAttendanceCallCount++;
          return [
            RecentReportModel(
              reportId: 'stu-att-1',
              reportType: 'STUDENT_DAILY_ATTENDANCE',
              generatedAt: '2026-01-15T10:30:00Z',
            ),
          ];
        };

        fakeDataSource.recentStaffAttendanceResponse = () async {
          staffAttendanceCallCount++;
          return [
            RecentReportModel(
              reportId: 'staff-att-1',
              reportType: 'STAFF_ABSENT',
              generatedAt: '2026-01-15T09:30:00Z',
            ),
          ];
        };

        fakeDataSource.recentStaffResponse = () async {
          staffCallCount++;
          return [
            RecentReportModel(
              reportId: 'staff-dir-1',
              reportType: 'STAFF_DETAILS',
              generatedAt: '2026-01-15T08:30:00Z',
            ),
          ];
        };

        fakeDataSource.recentStudentManagementResponse = () async {
          studentMgmtCallCount++;
          return [
            RecentReportModel(
              reportId: 'stu-mgmt-1',
              reportType: 'STUDENTS_AND_FAMILY',
              generatedAt: '2026-01-15T07:30:00Z',
            ),
          ];
        };

        final result = await repository.getRecentReports();

        expect(studentAttendanceCallCount, 1);
        expect(staffAttendanceCallCount, 1);
        expect(staffCallCount, 1);
        expect(studentMgmtCallCount, 1);
        expect(result, hasLength(4));
      });

      test(
        'deduplicates reports by reportId keeping last occurrence',
        () async {
          final duplicateReport = RecentReportModel(
            reportId: 'duplicate-id',
            reportType: 'STUDENT_DAILY_ATTENDANCE',
            generatedAt: '2026-01-15T10:00:00Z',
          );

          final duplicateReportNewer = RecentReportModel(
            reportId: 'duplicate-id',
            reportType: 'STUDENT_DAILY_ATTENDANCE',
            generatedAt: '2026-01-15T11:00:00Z',
          );

          fakeDataSource.recentStudentAttendanceResponse = () async => [
            duplicateReport,
          ];
          fakeDataSource.recentStaffAttendanceResponse = () async => [
            duplicateReportNewer,
          ];
          fakeDataSource.recentStaffResponse = () async => [];
          fakeDataSource.recentStudentManagementResponse = () async => [];

          final result = await repository.getRecentReports();

          expect(result, hasLength(1));
          expect(result[0].reportId, 'duplicate-id');
          expect(result[0].generatedAt, DateTime.parse('2026-01-15T11:00:00Z'));
        },
      );

      test('sorts reports by date descending (most recent first)', () async {
        fakeDataSource.recentStudentAttendanceResponse = () async => [
          RecentReportModel(
            reportId: 'old-1',
            reportType: 'STUDENT_DAILY_ATTENDANCE',
            generatedAt: '2026-01-10T10:00:00Z',
          ),
        ];

        fakeDataSource.recentStaffAttendanceResponse = () async => [
          RecentReportModel(
            reportId: 'newest-1',
            reportType: 'STAFF_ABSENT',
            generatedAt: '2026-01-20T10:00:00Z',
          ),
        ];

        fakeDataSource.recentStaffResponse = () async => [
          RecentReportModel(
            reportId: 'middle-1',
            reportType: 'STAFF_DETAILS',
            generatedAt: '2026-01-15T10:00:00Z',
          ),
        ];

        fakeDataSource.recentStudentManagementResponse = () async => [];

        final result = await repository.getRecentReports();

        expect(result, hasLength(3));
        expect(result[0].reportId, 'newest-1');
        expect(result[1].reportId, 'middle-1');
        expect(result[2].reportId, 'old-1');
      });

      test('handles empty results from all sources', () async {
        fakeDataSource.recentStudentAttendanceResponse = () async => [];
        fakeDataSource.recentStaffAttendanceResponse = () async => [];
        fakeDataSource.recentStaffResponse = () async => [];
        fakeDataSource.recentStudentManagementResponse = () async => [];

        final result = await repository.getRecentReports();

        expect(result, isEmpty);
      });

      test(
        'does not cache recent reports and fetches from API every time',
        () async {
          var apiCallCount = 0;
          fakeDataSource.recentStudentAttendanceResponse = () async {
            apiCallCount++;
            return [
              RecentReportModel(
                reportId: 'report-$apiCallCount',
                reportType: 'STUDENT_DAILY_ATTENDANCE',
                generatedAt: '2026-01-15T10:00:00Z',
              ),
            ];
          };
          fakeDataSource.recentStaffAttendanceResponse = () async => [];
          fakeDataSource.recentStaffResponse = () async => [];
          fakeDataSource.recentStudentManagementResponse = () async => [];

          await repository.getRecentReports();
          final secondResult = await repository.getRecentReports();

          // API should be called twice since caching is disabled
          expect(apiCallCount, 2);
          expect(secondResult, hasLength(1));
          expect(secondResult[0].reportId, 'report-2');
        },
      );

      test(
        'propagates a Failure when every source fails (no more silent [])',
        () async {
          fakeDataSource.shouldThrow = true;

          expect(
            () => repository.getRecentReports(),
            throwsA(isA<ServerFailure>()),
          );
        },
      );

      test(
        'returns partial results and logs when only some sources fail',
        () async {
          fakeDataSource.recentStudentAttendanceResponse = () async => [
            RecentReportModel(
              reportId: 'ok-1',
              reportType: 'STUDENT_DAILY_ATTENDANCE',
              generatedAt: '2026-01-15T10:00:00Z',
            ),
          ];
          fakeDataSource.recentStaffAttendanceResponse = () async =>
              throw Exception('Staff attendance MS down');
          fakeDataSource.recentStaffResponse = () async => [];
          fakeDataSource.recentStudentManagementResponse = () async => [];

          // One source failing must not discard results from the others —
          // this preserves the original graceful-degradation UX while no
          // longer hiding the failure (it's logged via AppLogger.e).
          final result = await repository.getRecentReports();

          expect(result, hasLength(1));
          expect(result[0].reportId, 'ok-1');
        },
      );
    });

    group('getStudentTags', () {
      test('returns list of tags from API', () async {
        fakeDataSource.tagsResponse = () async => [
          'VIP',
          'SCHOLARSHIP',
          'MEDICAL',
        ];

        final result = await repository.getStudentTags();

        expect(result, hasLength(3));
        expect(result, containsAll(['VIP', 'SCHOLARSHIP', 'MEDICAL']));
      });

      test('caches tags and returns from cache on second call', () async {
        var apiCallCount = 0;
        fakeDataSource.tagsResponse = () async {
          apiCallCount++;
          return ['TAG-${apiCallCount}'];
        };

        await repository.getStudentTags();
        expect(apiCallCount, 1);

        await repository.getStudentTags();
        expect(apiCallCount, 1);
      });

      test('handles empty tag list', () async {
        fakeDataSource.tagsResponse = () async => [];

        final result = await repository.getStudentTags();

        expect(result, isEmpty);
      });

      test('propagates API errors', () async {
        fakeDataSource.shouldThrow = true;

        expect(() => repository.getStudentTags(), throwsException);
      });
    });

    group('Cache behavior', () {
      test('respects 30-minute cache duration for tags', () async {
        fakeDataSource.tagsResponse = () async => ['VIP', 'SCHOLARSHIP'];

        // Cache should be used within 30 minutes
        await repository.getStudentTags();
        final cachedResult = await repository.getStudentTags();

        expect(cachedResult, containsAll(['VIP', 'SCHOLARSHIP']));
      });

      test('uses feature_resource_cache pattern for tag cache keys', () async {
        fakeDataSource.tagsResponse = () async => ['VIP', 'SCHOLARSHIP'];

        await repository.getStudentTags();

        // Verify storage was called with proper pattern
        expect(
          fakeStorageService._storage.keys.any(
            (key) => key.startsWith('reports_tags_cache_'),
          ),
          isTrue,
        );
      });
    });

    group('Model to Entity conversion', () {
      test('converts ReportResponseModel to ReportEntity correctly', () async {
        fakeDataSource.generateReportResponse = () async => ReportResponseModel(
          reportId: 'report-123',
          reportType: 'STUDENT_DAILY_ATTENDANCE',
          generatedAt: '2026-01-15T10:30:00Z',
          assetCode: 'asset-456',
          fileName: 'report.xlsx',
        );

        final params = ReportRequestParams(
          reportType: ReportType.studentDailyAttendance,
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 15),
          schoolName: 'Dummy School',
        );

        final result = await repository.generateReport(params);

        expect(result.reportId, 'report-123');
        expect(result.reportType, ReportType.studentDailyAttendance);
        expect(result.assetCode, 'asset-456');
        expect(result.fileName, 'report.xlsx');
        expect(result.generatedAt, isA<DateTime>());
      });

      test(
        'converts RecentReportModel to ReportMetadataEntity correctly',
        () async {
          fakeDataSource.recentStudentAttendanceResponse = () async => [
            RecentReportModel(
              reportId: 'report-123',
              reportType: 'STUDENT_DAILY_ATTENDANCE',
              generatedAt: '2026-01-15T10:30:00Z',
              assetCode: 'asset-456',
              fileName: 'report.xlsx',
            ),
          ];
          fakeDataSource.recentStaffAttendanceResponse = () async => [];
          fakeDataSource.recentStaffResponse = () async => [];
          fakeDataSource.recentStudentManagementResponse = () async => [];

          final result = await repository.getRecentReports();

          expect(result[0].reportId, 'report-123');
          expect(result[0].reportType, ReportType.studentDailyAttendance);
          expect(result[0].assetCode, 'asset-456');
          expect(result[0].fileName, 'report.xlsx');
        },
      );

      test(
        'throws for an unrecognized reportType instead of silently falling back',
        () async {
          fakeDataSource.generateReportResponse = () async =>
              ReportResponseModel(
                reportId: 'report-123',
                reportType: 'INVALID_TYPE',
                generatedAt: '2026-01-15T10:30:00Z',
              );

          final params = ReportRequestParams(
            reportType: ReportType.studentDailyAttendance,
            startDate: DateTime(2026, 1, 15),
            schoolName: 'Dummy School',
            endDate: DateTime(2026, 1, 15),
          );

          // An unrecognized reportType in the backend response means the
          // contract has drifted — failing loudly surfaces that immediately
          // instead of silently mislabeling the report.
          expect(
            () => repository.generateReport(params),
            throwsA(isA<FormatException>()),
          );
        },
      );
    });
  });
}
