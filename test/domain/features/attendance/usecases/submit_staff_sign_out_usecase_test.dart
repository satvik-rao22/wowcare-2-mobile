import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_out_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_out_usecase.dart';

const _sampleRequest = StaffSignOutRequest(
  attendanceDate: '2026-08-27',
  staffCode: 'STF-1',
  staffCodes: ['STF-1'],
  classroomCode: 'CLS_1',
  classroomCodeByStaffCode: {'STF-1': 'CLS_1'},
  signOutMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: false,
  timeZone: 'Asia/Kolkata',
  occurredAtIso: '2026-08-27T09:00:00.000Z',
);

/// Fake repository: captures the arguments and returns/throws on demand.
class _FakeAttendanceRepository implements AttendanceRepository {
  StaffSignOutRequest? capturedRequest;
  bool? capturedIsSelf;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStaffSignOut({
    required StaffSignOutRequest request,
    bool isSelf = false,
    String? idempotencyKey,
  }) async {
    capturedRequest = request;
    capturedIsSelf = isSelf;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('SubmitStaffSignOutUseCase', () {
    late _FakeAttendanceRepository repo;
    late SubmitStaffSignOutUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = SubmitStaffSignOutUseCase(repo);
    });

    test('forwards request and isSelf, and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Signed-Out successfully',
      );
      repo.resultToReturn = expected;

      final result = await useCase(request: _sampleRequest, isSelf: true);

      expect(result, same(expected));
      expect(repo.capturedRequest, same(_sampleRequest));
      expect(repo.capturedIsSelf, isTrue);
    });

    test('defaults isSelf to false when omitted', () async {
      repo.resultToReturn = const AttendanceActionResult(
        success: true,
        message: 'ok',
      );

      await useCase(request: _sampleRequest);

      expect(repo.capturedIsSelf, isFalse);
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(request: _sampleRequest, isSelf: false),
        throwsA(same(failure)),
      );
    });
  });
}
