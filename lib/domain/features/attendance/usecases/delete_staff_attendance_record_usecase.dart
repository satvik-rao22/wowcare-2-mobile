import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/attendance_repository.dart';

/// Deletes a staff attendance record (sign-in / sign-out / transfer day row).
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: completes normally on success and propagates any error
/// unchanged, so callers keep their current success/error handling verbatim.
class DeleteStaffAttendanceRecordUseCase {
  const DeleteStaffAttendanceRecordUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<void> call({
    required String attendanceRecordCode,
    required String staffCode,
  }) {
    return AppEvents.track(
      AppEvent.attendanceStaffRecordDelete,
      () => _repository.deleteStaffAttendanceRecord(
        attendanceRecordCode: attendanceRecordCode,
        staffCode: staffCode,
      ),
    );
  }
}
