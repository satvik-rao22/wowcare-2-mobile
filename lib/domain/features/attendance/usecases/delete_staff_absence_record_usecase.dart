import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/attendance_repository.dart';

/// Deletes a staff absence record (e.g. before an admin override sign-in).
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: completes normally on success and propagates any error
/// unchanged, so callers keep their current success/error handling verbatim.
class DeleteStaffAbsenceRecordUseCase {
  const DeleteStaffAbsenceRecordUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<void> call({
    required String absenceRecordCode,
    required String staffCode,
  }) {
    return AppEvents.track(
      AppEvent.attendanceStaffAbsenceDelete,
      () => _repository.deleteStaffAbsenceRecord(
        absenceRecordCode: absenceRecordCode,
        staffCode: staffCode,
      ),
    );
  }
}
