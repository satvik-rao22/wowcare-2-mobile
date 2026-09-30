import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/reports/datasources/reports_remote_datasource_impl.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';

class FakeDio extends Fake implements Dio {
  dynamic Function(String path)? responseBuilder;
  bool shouldThrow = false;
  DioException? exception;

  @override
  BaseOptions get options => BaseOptions();

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    dynamic onSendProgress,
    dynamic onReceiveProgress,
    String? baseUrl,
    Options? options,
    ProgressCallback? onUploadProgress,
  }) async {
    if (shouldThrow) {
      throw exception ??
          DioException(
            requestOptions: RequestOptions(path: path),
            message: 'Network error',
          );
    }
    var responseData = responseBuilder?.call(path);
    if (responseData is Map) {
      responseData = Map<String, dynamic>.from(responseData);
    }
    return Response<T>(
      data: responseData as T?,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    String? baseUrl,
  }) async {
    if (shouldThrow) {
      throw exception ??
          DioException(
            requestOptions: RequestOptions(path: path),
            message: 'Network error',
          );
    }
    var responseData = responseBuilder?.call(path);
    if (responseData is Map) {
      responseData = Map<String, dynamic>.from(responseData);
    }
    return Response<T>(
      data: responseData as T?,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class FakeStorageService extends Fake implements StorageService {
  @override
  Future<String?> getString(String key) async {
    return 'school-123';
  }
}

void main() {
  late FakeDio fakeDio;
  late FakeStorageService fakeStorageService;
  late ReportsRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeDio = FakeDio();
    fakeStorageService = FakeStorageService();
    dataSource = ReportsRemoteDataSourceImpl(fakeDio, fakeStorageService);
  });

  group('ReportsRemoteDataSourceImpl', () {
    group('generateReport', () {
      test(
        'routes STUDENT_DAILY_ATTENDANCE to student-attendance endpoint',
        () async {
          const reportType = ReportType.studentDailyAttendance;
          final requestBody = <String, dynamic>{
            'startDate': '2026-01-01',
            'endDate': '2026-01-01',
          };
          final responseData = {
            'reportId': 'report-123',
            'reportType': 'STUDENT_DAILY_ATTENDANCE',
            'generatedAt': '2026-01-15T10:30:00Z',
            'assetCode': 'asset-456',
            'fileName': 'report.xlsx',
          };

          fakeDio.responseBuilder = (path) {
            if (path.endsWith(
              '/api/v1/attendance/student-attendance/reports/generate',
            )) {
              return responseData;
            }
            return null;
          };

          final result = await dataSource.generateReport(
            reportType: reportType,
            payload: _RawPayload(requestBody),
          );

          expect(result.reportId, 'report-123');
          expect(result.reportType, 'STUDENT_DAILY_ATTENDANCE');
          expect(result.assetCode, 'asset-456');
          expect(result.fileName, 'report.xlsx');
        },
      );

      test('routes STUDENT_ABSENT to student-attendance endpoint', () async {
        const reportType = ReportType.studentAbsent;
        final requestBody = <String, dynamic>{'startDate': '2026-01-01'};

        fakeDio.responseBuilder = (path) {
          if (path.endsWith(
            '/api/v1/attendance/student-attendance/reports/generate',
          )) {
            return {
              'reportId': 'report-789',
              'reportType': 'STUDENT_ABSENT',
              'generatedAt': '2026-01-15T10:30:00Z',
            };
          }
          return null;
        };

        final result = await dataSource.generateReport(
          reportType: reportType,
          payload: _RawPayload(requestBody),
        );

        expect(result.reportType, 'STUDENT_ABSENT');
      });

      test('routes STAFF_ABSENT to staff-attendance endpoint', () async {
        const reportType = ReportType.staffAbsent;
        final requestBody = <String, dynamic>{'startDate': '2026-01-01'};

        fakeDio.responseBuilder = (path) {
          if (path.endsWith(
            '/api/v1/attendance/staff-attendance/reports/generate',
          )) {
            return {
              'reportId': 'report-555',
              'reportType': 'STAFF_ABSENT',
              'generatedAt': '2026-01-15T10:30:00Z',
            };
          }
          return null;
        };

        final result = await dataSource.generateReport(
          reportType: reportType,
          payload: _RawPayload(requestBody),
        );

        expect(result.reportType, 'STAFF_ABSENT');
      });

      test('routes STAFF_DETAILS to staff endpoint', () async {
        const reportType = ReportType.staffDetails;
        final requestBody = <String, dynamic>{
          'classroomCodes': ['CLASS-1'],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/staff/staff/reports/generate')) {
            return {
              'reportId': 'report-dir-1',
              'reportType': 'STAFF_DETAILS',
              'generatedAt': '2026-01-15T10:30:00Z',
            };
          }
          return null;
        };

        final result = await dataSource.generateReport(
          reportType: reportType,
          payload: _RawPayload(requestBody),
        );

        expect(result.reportType, 'STAFF_DETAILS');
      });

      test('routes STUDENTS_AND_FAMILY to student endpoint', () async {
        const reportType = ReportType.studentsAndFamily;
        final requestBody = <String, dynamic>{
          'classroomCodes': ['CLASS-1'],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/student/student/reports/generate')) {
            return {
              'reportId': 'report-family-1',
              'reportType': 'STUDENTS_AND_FAMILY',
              'generatedAt': '2026-01-15T10:30:00Z',
            };
          }
          return null;
        };

        final result = await dataSource.generateReport(
          reportType: reportType,
          payload: _RawPayload(requestBody),
        );

        expect(result.reportType, 'STUDENTS_AND_FAMILY');
      });

      test('routes EMERGENCY_CONTACTS to student endpoint', () async {
        const reportType = ReportType.emergencyContacts;
        final requestBody = <String, dynamic>{};

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/student/student/reports/generate')) {
            return {
              'reportId': 'report-emergency-1',
              'reportType': 'EMERGENCY_CONTACTS',
              'generatedAt': '2026-01-15T10:30:00Z',
            };
          }
          return null;
        };

        final result = await dataSource.generateReport(
          reportType: reportType,
          payload: _RawPayload(requestBody),
        );

        expect(result.reportType, 'EMERGENCY_CONTACTS');
      });

      test('routes IMMUNIZATION to immunization endpoint', () async {
        const reportType = ReportType.immunization;
        final requestBody = <String, dynamic>{
          'studentCodes': ['STU-1'],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/student/student/reports/generate')) {
            return {
              'reportId': 'report-immun-1',
              'reportType': 'IMMUNIZATION',
              'generatedAt': '2026-01-15T10:30:00Z',
            };
          }
          return null;
        };

        final result = await dataSource.generateReport(
          reportType: reportType,
          payload: _RawPayload(requestBody),
        );

        expect(result.reportType, 'IMMUNIZATION');
      });

      // No "unknown report type" test: reportType is now a ReportType enum,
      // not a String, and ReportsRemoteDataSourceImpl._generateEndpointFor
      // switches over it exhaustively with no default case. The analyzer
      // rejects any new ReportType case that isn't handled there at
      // compile time, so the old runtime ArgumentError path is structurally
      // unreachable — there is nothing left for a test to exercise.

      test(
        'routes BILLING_TRANSACTION to billing transaction endpoint via GET',
        () async {
          const reportType = ReportType.billingTransaction;
          final requestBody = <String, dynamic>{
            'dateFrom': '2026-01-01T00:00:00.000Z',
            'dateTo': '2026-01-15T00:00:00.000Z',
            'paymentMethods': ['Card', 'Cash'],
            'transactionStatuses': ['Success'],
          };
          // The billing endpoints stream the file back as bytes
          // (ResponseType.bytes) rather than returning JSON, so the fake must
          // answer with bytes or generateReport null-checks on response.data.
          final responseData = utf8.encode('fake-xlsx-bytes');

          String? capturedPath;
          fakeDio.responseBuilder = (path) {
            capturedPath = path;
            if (path.endsWith('/api/v1/accounts/reports/billing/TRANSACTION')) {
              return responseData;
            }
            return null;
          };

          final result = await dataSource.generateReport(
            reportType: reportType,
            payload: _RawPayload(requestBody),
          );

          expect(
            capturedPath,
            endsWith('/api/v1/accounts/reports/billing/TRANSACTION'),
          );
          // The datasource stamps ReportType.billingTransaction.backendValue,
          // which is 'TRANSACTION'.
          expect(result.reportType, 'TRANSACTION');
        },
      );

      test(
        'throws FormatException when backend response is missing required fields',
        () async {
          const reportType = ReportType.studentDailyAttendance;
          final requestBody = <String, dynamic>{'startDate': '2026-01-01'};

          fakeDio.responseBuilder = (_) => null;

          expect(
            () => dataSource.generateReport(
              reportType: reportType,
              payload: _RawPayload(requestBody),
            ),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test('propagates DioException from network errors', () async {
        const reportType = ReportType.studentDailyAttendance;
        final requestBody = <String, dynamic>{'startDate': '2026-01-01'};

        fakeDio.shouldThrow = true;
        fakeDio.exception = DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Connection timeout',
          type: DioExceptionType.connectionTimeout,
        );

        expect(
          () => dataSource.generateReport(
            reportType: reportType,
            payload: _RawPayload(requestBody),
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getRecentStudentAttendanceReports', () {
      test('returns list of recent student attendance reports', () async {
        final responseData = {
          'reports': [
            {
              'reportId': 'recent-1',
              'reportType': 'STUDENT_DAILY_ATTENDANCE',
              'generatedAt': '2026-01-15T10:30:00Z',
            },
            {
              'reportId': 'recent-2',
              'reportType': 'STUDENT_DAILY_ATTENDANCE',
              'generatedAt': '2026-01-14T10:30:00Z',
            },
          ],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith(
            '/api/v1/attendance/student-attendance/reports/recent',
          )) {
            return responseData;
          }
          return null;
        };

        final result = await dataSource.getRecentStudentAttendanceReports();

        expect(result, hasLength(2));
        expect(result[0].reportId, 'recent-1');
        expect(result[1].reportId, 'recent-2');
      });

      test(
        'returns list of recent student attendance reports with nested data.reports format',
        () async {
          final responseData = {
            'data': {
              'reports': [
                {
                  'reportId': 'recent-nested-1',
                  'reportType': 'STUDENT_DAILY_ATTENDANCE',
                  'generatedAt': '2026-01-15T10:30:00Z',
                },
              ],
            },
          };

          fakeDio.responseBuilder = (path) {
            if (path.endsWith(
              '/api/v1/attendance/student-attendance/reports/recent',
            )) {
              return responseData;
            }
            return null;
          };

          final result = await dataSource.getRecentStudentAttendanceReports();

          expect(result, hasLength(1));
          expect(result[0].reportId, 'recent-nested-1');
        },
      );

      test('handles empty reports list', () async {
        fakeDio.responseBuilder = (path) => {'reports': []};

        final result = await dataSource.getRecentStudentAttendanceReports();

        expect(result, isEmpty);
      });

      test('handles null response data', () async {
        fakeDio.responseBuilder = (_) => null;

        final result = await dataSource.getRecentStudentAttendanceReports();

        expect(result, isEmpty);
      });

      test('handles missing reports field', () async {
        fakeDio.responseBuilder = (_) => {};

        final result = await dataSource.getRecentStudentAttendanceReports();

        expect(result, isEmpty);
      });
    });

    group('getRecentStaffAttendanceReports', () {
      test('returns list of recent staff attendance reports', () async {
        final responseData = {
          'reports': [
            {
              'reportId': 'staff-recent-1',
              'reportType': 'STAFF_ABSENT',
              'generatedAt': '2026-01-15T10:30:00Z',
            },
          ],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith(
            '/api/v1/attendance/staff-attendance/reports/recent',
          )) {
            return responseData;
          }
          return null;
        };

        final result = await dataSource.getRecentStaffAttendanceReports();

        expect(result, hasLength(1));
        expect(result[0].reportId, 'staff-recent-1');
      });

      test('handles empty list', () async {
        fakeDio.responseBuilder = (_) => {'reports': []};

        final result = await dataSource.getRecentStaffAttendanceReports();

        expect(result, isEmpty);
      });
    });

    group('getRecentStaffReports', () {
      test('returns list of recent staff reports', () async {
        final responseData = {
          'reports': [
            {
              'reportId': 'staff-dir-1',
              'reportType': 'STAFF_DETAILS',
              'generatedAt': '2026-01-15T10:30:00Z',
            },
          ],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/staff/staff/reports/recent')) {
            return responseData;
          }
          return null;
        };

        final result = await dataSource.getRecentStaffReports();

        expect(result, hasLength(1));
        expect(result[0].reportId, 'staff-dir-1');
      });
    });

    group('getRecentStudentManagementReports', () {
      test('returns list of recent student management reports', () async {
        final responseData = {
          'reports': [
            {
              'reportId': 'mgmt-1',
              'reportType': 'STUDENTS_AND_FAMILY',
              'generatedAt': '2026-01-15T10:30:00Z',
            },
            {
              'reportId': 'mgmt-2',
              'reportType': 'EMERGENCY_CONTACTS',
              'generatedAt': '2026-01-14T10:30:00Z',
            },
          ],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/student/student/reports/recent')) {
            return responseData;
          }
          return null;
        };

        final result = await dataSource.getRecentStudentManagementReports();

        expect(result, hasLength(2));
        expect(result[0].reportId, 'mgmt-1');
        expect(result[1].reportId, 'mgmt-2');
      });
    });

    group('getStudentTags', () {
      test('returns list of student tags', () async {
        final responseData = {
          'tags': ['VIP', 'SCHOLARSHIP', 'MEDICAL'],
        };

        fakeDio.responseBuilder = (path) {
          if (path.endsWith('/api/v1/student/student-tags')) {
            return responseData;
          }
          return null;
        };

        final result = await dataSource.getStudentTags();

        expect(result, hasLength(3));
        expect(result, containsAll(['VIP', 'SCHOLARSHIP', 'MEDICAL']));
      });

      test('handles empty tags list', () async {
        fakeDio.responseBuilder = (_) => {'tags': []};

        final result = await dataSource.getStudentTags();

        expect(result, isEmpty);
      });

      test('handles null response data', () async {
        fakeDio.responseBuilder = (_) => null;

        final result = await dataSource.getStudentTags();

        expect(result, isEmpty);
      });

      test('handles tags with integer values', () async {
        fakeDio.responseBuilder = (_) => <String, dynamic>{
          'tags': [123, 456],
        };

        final result = await dataSource.getStudentTags();

        expect(result, hasLength(2));
        expect(result, containsAll(['123', '456']));
      });
    });

    group('getReportDownloadUrl', () {
      test('returns deliveryUrl immediately when asset is READY', () async {
        fakeDio.responseBuilder = (_) => {
          'data': {
            'assets': [
              {
                'assetCode': 'AST_123',
                'status': 'READY',
                'deliveryUrl': 'https://cdn.example.com/reports/report.pdf',
              },
            ],
          },
        };

        final result = await dataSource.getReportDownloadUrl('AST_123');
        expect(result, 'https://cdn.example.com/reports/report.pdf');
      });

      test('polls and returns URL when asset transitions to READY', () async {
        int pollCount = 0;
        fakeDio.responseBuilder = (_) {
          pollCount++;
          if (pollCount == 1) {
            return {
              'data': {
                'assets': [
                  {
                    'assetCode': 'AST_123',
                    'status': 'PROCESSING',
                    'originalDownloadUrl':
                        '/api/v1/media-assets/AST_123/artifacts/original',
                  },
                ],
              },
            };
          }
          return {
            'data': {
              'assets': [
                {
                  'assetCode': 'AST_123',
                  'status': 'READY',
                  'deliveryUrl': 'https://cdn.example.com/reports/report.pdf',
                },
              ],
            },
          };
        };

        final result = await dataSource.getReportDownloadUrl('AST_123');
        expect(result, 'https://cdn.example.com/reports/report.pdf');
        expect(pollCount, greaterThanOrEqualTo(2));
      });

      test('throws Exception when asset status is FAILED', () async {
        fakeDio.responseBuilder = (_) => {
          'data': {
            'assets': [
              {'assetCode': 'AST_123', 'status': 'FAILED'},
            ],
          },
        };

        expect(
          () => dataSource.getReportDownloadUrl('AST_123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('downloadReportFile', () {
      test('downloads bytes successfully', () async {
        fakeDio.responseBuilder = (_) => [1, 2, 3, 4, 5];

        final result = await dataSource.downloadReportFile(
          'https://cdn.example.com/reports/report.pdf',
        );

        expect(result, [1, 2, 3, 4, 5]);
      });
    });
  });
}

/// A payload that serialises to a literal map.
///
/// The datasource's job is endpoint routing and response handling — it treats
/// the payload as opaque and only calls `toJson()` — so these tests pin the
/// exact body rather than going through a params class.
class _RawPayload extends ReportRequestPayload {
  const _RawPayload(this._json);

  final Map<String, dynamic> _json;

  @override
  Map<String, dynamic> toJson() => _json;
}
