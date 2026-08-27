import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';

/// Fake repository: captures the arguments and returns/throws on demand.
/// Every other AttendanceRepository member routes through noSuchMethod and
/// throws if the use case unexpectedly calls it.
class _FakeAttendanceRepository implements AttendanceRepository {
  Map<String, dynamic>? capturedPayload;
  bool? capturedIsParent;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStudentSignIn({
    required Map<String, dynamic> payload,
    required bool isParent,
  }) async {
    capturedPayload = payload;
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

    test('forwards payload and isParent, and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Signed-In successfully',
      );
      repo.resultToReturn = expected;
      final payload = <String, dynamic>{
        'studentCodes': ['STU-1'],
        'method': 'APP',
      };

      final result = await useCase(payload: payload, isParent: false);

      expect(result, same(expected));
      expect(repo.capturedPayload, same(payload));
      expect(repo.capturedIsParent, isFalse);
    });

    test('passes isParent: true through unchanged', () async {
      repo.resultToReturn = const AttendanceActionResult(
        success: true,
        message: 'ok',
      );

      await useCase(payload: const <String, dynamic>{}, isParent: true);

      expect(repo.capturedIsParent, isTrue);
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(payload: const <String, dynamic>{}, isParent: false),
        throwsA(same(failure)),
      );
    });
  });
}
