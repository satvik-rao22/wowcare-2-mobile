import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';

const _sampleRequest = StaffSignInRequest(
  mode: StaffSignInMode.self,
  staffCode: 'STF-1',
  signInMethod: 'GPS',
  latitude: 0,
  longitude: 0,
  withinGeofence: true,
  timeZone: 'Asia/Kolkata',
  occurredAtIso: '2026-08-27T09:00:00.000Z',
  isExpectedToday: true,
);

/// Fake repository: captures the arguments and returns/throws on demand.
/// Every other AttendanceRepository member routes through noSuchMethod and
/// throws if the use case unexpectedly calls it.
class _FakeAttendanceRepository implements AttendanceRepository {
  StaffSignInRequest? capturedRequest;
  bool? capturedIsSelf;
  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;

  @override
  Future<AttendanceActionResult> submitStaffSignIn({
    required StaffSignInRequest request,
    required bool isSelf,
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
  group('SubmitStaffSignInUseCase', () {
    late _FakeAttendanceRepository repo;
    late SubmitStaffSignInUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = SubmitStaffSignInUseCase(repo);
    });

    test('forwards request and isSelf, and returns the repository result', () async {
      const expected = AttendanceActionResult(
        success: true,
        message: 'Signed-In successfully',
      );
      repo.resultToReturn = expected;

      final result = await useCase(request: _sampleRequest, isSelf: true);

      expect(result, same(expected));
      expect(repo.capturedRequest, same(_sampleRequest));
      expect(repo.capturedIsSelf, isTrue);
    });

    test('passes isSelf: false through unchanged', () async {
      repo.resultToReturn = const AttendanceActionResult(
        success: true,
        message: 'ok',
      );

      await useCase(request: _sampleRequest, isSelf: false);

      expect(repo.capturedIsSelf, isFalse);
    });

    test('propagates repository errors unchanged (no wrapping/swallowing)', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(request: _sampleRequest, isSelf: true),
        throwsA(same(failure)),
      );
    });
  });
}
