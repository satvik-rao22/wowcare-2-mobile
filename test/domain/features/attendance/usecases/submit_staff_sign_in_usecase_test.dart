import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';

/// Fake repository: captures the arguments and returns/throws on demand.
/// Every other AttendanceRepository member routes through noSuchMethod and
/// throws if the use case unexpectedly calls it.
class _FakeAttendanceRepository implements AttendanceRepository {
  Map<String, dynamic>? capturedPayload;
  bool? capturedIsSelf;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStaffSignIn({
    required Map<String, dynamic> payload,
    required bool isSelf,
  }) async {
    capturedPayload = payload;
    capturedIsSelf = isSelf;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('SubmitStaffSignInUseCase', () {
    late _FakeAttendanceRepository repo;
    late SubmitStaffSignInUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = SubmitStaffSignInUseCase(repo);
    });

    test('forwards payload and isSelf, and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Signed-In successfully',
      );
      repo.resultToReturn = expected;
      final payload = <String, dynamic>{
        'staffCode': 'STF-1',
        'method': 'GPS',
      };

      final result = await useCase(payload: payload, isSelf: true);

      expect(result, same(expected));
      expect(repo.capturedPayload, same(payload));
      expect(repo.capturedIsSelf, isTrue);
    });

    test('passes isSelf: false through unchanged', () async {
      repo.resultToReturn = const AttendanceActionResult(
        success: true,
        message: 'ok',
      );

      await useCase(payload: const <String, dynamic>{}, isSelf: false);

      expect(repo.capturedIsSelf, isFalse);
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(payload: const <String, dynamic>{}, isSelf: true),
        throwsA(same(failure)),
      );
    });
  });
}
