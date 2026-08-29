import '../entities/attendance_action_result.dart';
import '../entities/staff_sign_in_request.dart';
import '../repositories/attendance_repository.dart';

/// Submits a staff sign-in through the repository.
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly — restoring the
/// View → Cubit → UseCase → Repository chain for this write flow.
///
/// Behaviour is an exact pass-through: the backend `success`/`message`
/// [AttendanceActionResult] is returned as-is and any thrown error is
/// propagated unchanged, so existing callers keep their current success and
/// error handling verbatim.
class SubmitStaffSignInUseCase {
  const SubmitStaffSignInUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceActionResult> call({
    required StaffSignInRequest request,
    required bool isSelf,
    String? idempotencyKey,
  }) {
    return _repository.submitStaffSignIn(
      request: request,
      isSelf: isSelf,
      idempotencyKey: idempotencyKey,
    );
  }
}
