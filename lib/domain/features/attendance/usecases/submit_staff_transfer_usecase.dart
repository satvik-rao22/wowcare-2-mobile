import '../entities/attendance_action_result.dart';
import '../entities/staff_transfer_request.dart';
import '../repositories/attendance_repository.dart';

/// Submits a staff classroom transfer through the repository.
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: the backend `success`/`message` result is returned as-is and
/// any thrown error is propagated unchanged.
class SubmitStaffTransferUseCase {
  const SubmitStaffTransferUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<AttendanceActionResult> call({
    required StaffTransferRequest request,
    String? idempotencyKey,
  }) {
    return _repository.submitStaffTransfer(
      request: request,
      idempotencyKey: idempotencyKey,
    );
  }
}
