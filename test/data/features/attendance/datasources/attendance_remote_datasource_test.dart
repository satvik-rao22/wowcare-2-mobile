import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/attendance/datasources/attendance_remote_datasource.dart';

/// Records the RequestOptions it is handed and returns a 200 JSON body, so we
/// can assert exactly which endpoint/body/query the datasource built. Pattern
/// mirrors test/core/network/session_expired_replay_idempotency_test.dart.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{"data":{}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late Dio dio;
  late AttendanceRemoteDataSourceImpl ds;

  setUp(() {
    adapter = _CapturingAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    ds = AttendanceRemoteDataSourceImpl(dio);
  });

  group('postStudentSignIn', () {
    test('staff endpoint: forwards body to /student-attendance-records/sign-in',
        () async {
      final body = <String, dynamic>{'studentCodes': ['STU-1'], 'method': 'APP'};

      await ds.postStudentSignIn(body: body, isParent: false);

      final sent = adapter.captured!;
      expect(sent.method, 'POST');
      expect(sent.uri.toString(), contains('/student-attendance-records/sign-in'));
      // Staff path is NOT the parent path.
      expect(sent.uri.toString(), isNot(contains('parent-sign-in')));
      // The exact body the method was given is forwarded as the request data.
      expect(sent.data, same(body));
    });

    test('isParent toggle selects the parent-sign-in endpoint + forwards query',
        () async {
      final body = <String, dynamic>{'studentCodes': ['STU-1'], 'method': 'APP'};

      await ds.postStudentSignIn(
        body: body,
        queryParameters: <String, dynamic>{'guardianCode': 'GRD-9'},
        isParent: true,
      );

      final sent = adapter.captured!;
      expect(sent.method, 'POST');
      expect(sent.uri.toString(), contains('/student-attendance-records/parent-sign-in'));
      expect(sent.uri.queryParameters['guardianCode'], 'GRD-9');
      expect(sent.data, same(body));
    });
  });

  group('postStaffSignIn', () {
    test('isSelf=false posts to the bulk /staff-attendance-records/sign-in',
        () async {
      final body = <String, dynamic>{'staffCodes': ['STF-1']};

      await ds.postStaffSignIn(body: body, isSelf: false);

      final sent = adapter.captured!;
      expect(sent.method, 'POST');
      expect(sent.uri.toString(), contains('/staff-attendance-records/sign-in'));
      // Bulk endpoint is not the self endpoint.
      expect(sent.uri.toString(), isNot(contains('/sign-in/self')));
      expect(sent.data, same(body));
    });

    test('isSelf=true posts to the /staff-attendance-records/sign-in/self endpoint',
        () async {
      final body = <String, dynamic>{'staffCode': 'STF-1'};

      await ds.postStaffSignIn(body: body, isSelf: true);

      final sent = adapter.captured!;
      expect(sent.uri.toString(), contains('/staff-attendance-records/sign-in/self'));
      expect(sent.data, same(body));
    });
  });

  group('getStudentAttendanceExpectedSummaryCard (GET)', () {
    test('GETs the summary card path and forwards classroomCode as a query param',
        () async {
      await ds.getStudentAttendanceExpectedSummaryCard(classroomCode: 'CLS-7');

      final sent = adapter.captured!;
      expect(sent.method, 'GET');
      expect(sent.uri.toString(), contains('/student-attendance/expected/summary/card'));
      expect(sent.uri.queryParameters['classroomCode'], 'CLS-7');
    });

    test('omits classroomCode when it is blank', () async {
      await ds.getStudentAttendanceExpectedSummaryCard(classroomCode: '   ');

      final sent = adapter.captured!;
      expect(sent.method, 'GET');
      expect(sent.uri.queryParameters.containsKey('classroomCode'), isFalse);
    });
  });
}
