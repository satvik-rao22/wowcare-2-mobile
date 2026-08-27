import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_transfer_usecase.dart';

/// Fake repository: captures the arguments and returns/throws on demand.
/// Every other AttendanceRepository member routes through noSuchMethod and
/// throws if the use case unexpectedly calls it.
class _FakeAttendanceRepository implements AttendanceRepository {
  Map<String, dynamic>? capturedPayload;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStudentTransfer({
    required Map<String, dynamic> payload,
  }) async {
    capturedPayload = payload;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('SubmitStudentTransferUseCase', () {
    late _FakeAttendanceRepository repo;
    late SubmitStudentTransferUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = SubmitStudentTransferUseCase(repo);
    });

    test('forwards payload and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Transferred successfully',
      );
      repo.resultToReturn = expected;
      final payload = <String, dynamic>{
        'studentCodes': ['STU-1'],
        'toClassroomCode': 'CLS_1',
      };

      final result = await useCase(payload: payload);

      expect(result, same(expected));
      expect(repo.capturedPayload, same(payload));
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(payload: const <String, dynamic>{}),
        throwsA(same(failure)),
      );
    });
  });
}
