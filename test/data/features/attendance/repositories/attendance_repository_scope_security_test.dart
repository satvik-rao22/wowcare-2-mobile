import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/attendance/datasources/attendance_remote_datasource.dart';
import 'package:wowcare/data/features/attendance/repositories/attendance_repository_impl.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';

/// Storage returning configured values by key; null for anything unset.
class _ScopeStorage implements StorageService {
  _ScopeStorage(this.values);
  final Map<String, String?> values;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Captures the body the repository forwards to the sign-in endpoint.
class _CapturingDataSource implements AttendanceRemoteDataSource {
  Map<String, dynamic>? capturedBody;

  @override
  Future<Map<String, dynamic>?> postStudentSignIn({
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    capturedBody = body;
    return <String, dynamic>{'success': true};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// A scoped teacher: staff persona, non-admin staffType, cached allowed codes,
/// and an empty schoolCode so the cross-class resolver short-circuits to false
/// (no network) — which keeps the resolved scope non-empty.
Map<String, String?> _scopedStaff(List<String> codes) => <String, String?>{
  StorageKeys.activeSchoolRole: 'STAFF',
  StorageKeys.staffType: 'TEACHER',
  StorageKeys.staffAllowedClassroomCodes:
      '[${codes.map((c) => '"$c"').join(',')}]',
  StorageKeys.schoolCode: '',
};

StudentSignInRequest _req({required String signInMethod}) =>
    StudentSignInRequest(
      mode: StudentSignInMode.staff,
      studentCodes: const ['STU-1'],
      signInMethod: signInMethod,
      latitude: 0,
      longitude: 0,
      withinGeofence: true,
      timeZone: 'Asia/Kolkata',
    );

void main() {
  group('Attendance classroom-scope security', () {
    test(
      'non-empty storage-resolved scope is ALWAYS attached as '
      'allowedClassroomCodes on a non-kiosk student sign-in',
      () async {
        final ds = _CapturingDataSource();
        final repo = AttendanceRepositoryImpl(
          ds,
          _ScopeStorage(_scopedStaff(['A', 'B'])),
          _UnusedApiClient(),
        );

        await repo.submitStudentSignIn(
          request: _req(signInMethod: 'APP'),
          isParent: false,
        );

        expect(ds.capturedBody!['allowedClassroomCodes'], ['A', 'B']);
      },
    );

    test(
      'KIOSK method skips scope application entirely — no allowedClassroomCodes',
      () async {
        final ds = _CapturingDataSource();
        final repo = AttendanceRepositoryImpl(
          ds,
          _ScopeStorage(_scopedStaff(['A', 'B'])),
          _UnusedApiClient(),
        );

        await repo.submitStudentSignIn(
          request: _req(signInMethod: 'KIOSK'),
          isParent: false,
        );

        expect(
          ds.capturedBody!.containsKey('allowedClassroomCodes'),
          isFalse,
        );
      },
    );

    test(
      'CLIENT-TRUST (documents current behaviour, ties to the backend-owned IDOR '
      'finding): the client forwards whatever scope storage holds, UNVERIFIED — '
      'a wrong-school code in storage is sent to the server as-is. The server, '
      'not the client, is the object-level-authz trust boundary. This is '
      'documentation, NOT an endorsement, and must not be "fixed" here.',
      () async {
        final ds = _CapturingDataSource();
        final repo = AttendanceRepositoryImpl(
          ds,
          _ScopeStorage(_scopedStaff(['WRONG-SCHOOL-ROOM'])),
          _UnusedApiClient(),
        );

        await repo.submitStudentSignIn(
          request: _req(signInMethod: 'APP'),
          isParent: false,
        );

        expect(ds.capturedBody!['allowedClassroomCodes'], ['WRONG-SCHOOL-ROOM']);
      },
    );

    test(
      'admin persona (SCHOOL_ADMIN) is unscoped — allowedClassroomCodes is empty',
      () async {
        final ds = _CapturingDataSource();
        final repo = AttendanceRepositoryImpl(
          ds,
          _ScopeStorage(<String, String?>{
            StorageKeys.activeSchoolRole: 'STAFF',
            StorageKeys.staffType: 'SCHOOL_ADMIN',
            StorageKeys.schoolCode: '',
          }),
          _UnusedApiClient(),
        );

        await repo.submitStudentSignIn(
          request: _req(signInMethod: 'APP'),
          isParent: false,
        );

        expect(ds.capturedBody!['allowedClassroomCodes'], isEmpty);
      },
    );
  });
}
