import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';

const _request = StudentSignInRequest(
  mode: StudentSignInMode.staff,
  studentCodes: ['STU-1'],
  signInMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: true,
  timeZone: 'Asia/Kolkata',
);

class _FakeAttendanceRepository implements AttendanceRepository {
  StudentSignInRequest? capturedRequest;
  bool? capturedIsParent;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStudentSignIn({
    required StudentSignInRequest request,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    capturedRequest = request;
    capturedIsParent = isParent;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('SubmitStudentSignInUseCase', () {
    late _FakeAttendanceRepository repo;
    late SubmitStudentSignInUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = SubmitStudentSignInUseCase(repo);
    });

    test('forwards request and isParent, and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Signed-In successfully',
      );
      repo.resultToReturn = expected;

      final result = await useCase(request: _request, isParent: false);

      expect(result, same(expected));
      expect(repo.capturedRequest, same(_request));
      expect(repo.capturedIsParent, isFalse);
    });

    test('passes isParent: true through unchanged', () async {
      repo.resultToReturn = const AttendanceActionResult(
        success: true,
        message: 'ok',
      );

      await useCase(request: _request, isParent: true);

      expect(repo.capturedIsParent, isTrue);
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(request: _request, isParent: false),
        throwsA(same(failure)),
      );
    });
  });
}
