import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_transfer_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_transfer_usecase.dart';

const _request = StaffTransferRequest(
  staffCode: 'STF-1',
  staffCodes: ['STF-1'],
  toClassroomCode: 'CLS_1',
  toClassroomCodeByStaffCode: {'STF-1': 'CLS_1'},
  timeZone: 'Asia/Kolkata',
  transferredAt: '2026-08-27T09:00:00.000Z',
);

class _FakeAttendanceRepository implements AttendanceRepository {
  StaffTransferRequest? capturedRequest;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStaffTransfer({
    required StaffTransferRequest request,
    String? idempotencyKey,
  }) async {
    capturedRequest = request;
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

    test('forwards request and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Transferred successfully',
      );
      repo.resultToReturn = expected;

      final result = await useCase(request: _request);

      expect(result, same(expected));
      expect(repo.capturedRequest, same(_request));
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(() => useCase(request: _request), throwsA(same(failure)));
    });
  });
}
