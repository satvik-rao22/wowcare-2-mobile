import '../entities/attendance_action_result.dart';
import '../entities/student_sign_in_request.dart';
import '../repositories/attendance_repository.dart';

/// Submits a student sign-in through the repository.
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly — restoring the
/// View → Cubit → UseCase → Repository chain for this write flow.
///
/// Behaviour is an exact pass-through: the backend `success`/`message`
/// [AttendanceActionResult] is returned as-is and any thrown error is
/// propagated unchanged, so existing callers keep their current success and
/// error handling verbatim.
class SubmitStudentSignInUseCase {
  const SubmitStudentSignInUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceActionResult> call({
    required StudentSignInRequest request,
    required bool isParent,
  }) {
    return _repository.submitStudentSignIn(request: request, isParent: isParent);
  }
}
