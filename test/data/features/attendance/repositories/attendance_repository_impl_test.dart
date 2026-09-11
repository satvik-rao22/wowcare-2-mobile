import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/attendance/datasources/attendance_remote_datasource.dart';
import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';
import 'package:wowcare/data/features/attendance/repositories/attendance_repository_impl.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';

/// StorageService fake that answers every read with null/empty, so all
/// classroom-scope resolution collapses to the unscoped (`[]`) path — the
/// persona resolves to neither guardian nor staff, so no self-heal / DI /
/// network is ever touched. Writes are no-ops.
class _EmptyStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> saveString(String key, String value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// ApiClient is only consumed by timezone-resolving paths (update/create
/// record); the methods under test never touch it, so it stays unimplemented.
class _UnusedApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

/// Remote datasource fake: overrides only the members the repository exercises,
/// capturing their arguments and returning canned values. Everything else
/// throws via [noSuchMethod] so an unexpected call is loud.
class _FakeRemoteDataSource implements AttendanceRemoteDataSource {
  // postStudentSignIn capture + canned response.
  Map<String, dynamic>? capturedSignInBody;
  bool? capturedIsParent;
  Map<String, dynamic>? signInResponse;
  Object? signInError;

  // getStudentAttendanceDaily canned page model.
  StudentAttendanceDailyPageModel? dailyPageModel;

  @override
  Future<Map<String, dynamic>?> postStudentSignIn({
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    capturedSignInBody = body;
    capturedIsParent = isParent;
    if (signInError != null) throw signInError!;
    return signInResponse;
  }

  @override
  Future<StudentAttendanceDailyPageModel> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
    required List<String> allowedClassroomCodes,
  }) async {
    return dailyPageModel!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

AttendanceRepositoryImpl _buildRepo(_FakeRemoteDataSource ds) =>
    AttendanceRepositoryImpl(ds, _EmptyStorage(), _UnusedApiClient());

const _staffRequest = StudentSignInRequest(
  mode: StudentSignInMode.staff,
  studentCodes: ['STU-1'],
  signInMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: true,
  timeZone: 'Asia/Kolkata',
  attendanceDate: '2026-08-29',
  staffCode: 'STF-1',
  classroomCode: 'CLS-1',
);

void main() {
  group('AttendanceRepositoryImpl.submitStudentSignIn', () {
    test(
      'forwards request.toPayload() as the datasource body and maps the '
      'response Map into an AttendanceActionResult',
      () async {
        final ds = _FakeRemoteDataSource()
          ..signInResponse = <String, dynamic>{
            'success': true,
            'message': 'Signed-In successfully',
          };
        final repo = _buildRepo(ds);

        final result = await repo.submitStudentSignIn(
          request: _staffRequest,
          isParent: false,
        );

        // Body forwarded is the request's own payload (same student codes/method).
        expect(ds.capturedIsParent, isFalse);
        expect(ds.capturedSignInBody, isNotNull);
        expect(ds.capturedSignInBody!['studentCodes'], ['STU-1']);
        expect(ds.capturedSignInBody!['method'], 'APP');
        // Unscoped persona → an (empty) allowedClassroomCodes key was applied.
        expect(ds.capturedSignInBody!.containsKey('allowedClassroomCodes'), isTrue);

        // Response Map maps onto the domain result.
        expect(result.success, isTrue);
        expect(result.message, 'Signed-In successfully');
      },
    );

    test(
      'falls back to the default message when the response omits "message" and '
      'reports success=false when the backend says so',
      () async {
        final ds = _FakeRemoteDataSource()
          ..signInResponse = <String, dynamic>{'success': false};
        final repo = _buildRepo(ds);

        final result = await repo.submitStudentSignIn(
          request: _staffRequest,
          isParent: false,
        );

        expect(result.success, isFalse);
        expect(result.message, 'Signed-In successfully');
      },
    );

    test('propagates a datasource error unchanged (same instance)', () async {
      final error = Exception('network down');
      final ds = _FakeRemoteDataSource()..signInError = error;
      final repo = _buildRepo(ds);

      await expectLater(
        () => repo.submitStudentSignIn(request: _staffRequest, isParent: false),
        throwsA(same(error)),
      );
    });
  });

  group('AttendanceRepositoryImpl.getStudentAttendanceDaily', () {
    test('maps the datasource page model into the domain page entity', () async {
      final ds = _FakeRemoteDataSource()
        ..dailyPageModel = const StudentAttendanceDailyPageModel(
          items: <StudentAttendanceDailyItemModel>[],
          page: 2,
          size: 5,
          totalPages: 3,
          totalElements: 11,
          hasMore: true,
        );
      final repo = _buildRepo(ds);

      // page != 0 skips the cache branch entirely (no CacheManager writes).
      final entity = await repo.getStudentAttendanceDaily(
        attendanceDate: '2026-08-29',
        page: 1,
      );

      expect(entity.items, isEmpty);
      expect(entity.page, 2);
      expect(entity.size, 5);
      expect(entity.totalPages, 3);
      expect(entity.totalElements, 11);
      expect(entity.hasMore, isTrue);
    });
  });
}
