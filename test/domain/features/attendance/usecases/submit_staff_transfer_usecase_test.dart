import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_transfer_usecase.dart';

/// Fake repository: captures the arguments and returns/throws on demand.
/// Every other AttendanceRepository member routes through noSuchMethod and
/// throws if the use case unexpectedly calls it.
class _FakeAttendanceRepository implements AttendanceRepository {
  Map<String, dynamic>? capturedPayload;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStaffTransfer({
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
  group('SubmitStaffTransferUseCase', () {
    late _FakeAttendanceRepository repo;
    late SubmitStaffTransferUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = SubmitStaffTransferUseCase(repo);
    });

    test('forwards payload and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Transferred successfully',
      );
      repo.resultToReturn = expected;
      final payload = <String, dynamic>{
        'staffCodes': ['STF-1'],
        'toClassroomCode': 'CLS_2',
      };

      final result = await useCase(payload: payload);

      expect(result, same(expected));
      expect(repo.capturedPayload, same(payload));
    });

    test('a success:false response is returned unchanged (no throw)', () async {
      const expected = AttendanceActionResult(
        success: false,
        message: 'Already in that classroom',
      );
      repo.resultToReturn = expected;

      final result = await useCase(payload: const <String, dynamic>{});

      expect(result, same(expected));
      expect(result.success, isFalse);
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
