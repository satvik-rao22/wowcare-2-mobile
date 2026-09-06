import '../entities/staff_attendance_daily_update_request.dart';
import '../repositories/attendance_repository.dart';

/// Mirrors [UpdateStudentAttendanceRecordUseCase] — the staff edit-attendance
/// cubit was the one place still taking [AttendanceRepository] directly
/// instead of through a use case like its student-side counterpart already
/// does.
class UpdateStaffAttendanceRecordUseCase {
  UpdateStaffAttendanceRecordUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<void> call({
    required String attendanceCode,
    required StaffAttendanceDailyUpdateRequest request,
  }) {
    return _repository.updateStaffAttendanceDailyRecord(
      attendanceCode: attendanceCode,
      request: request,
    );
  }
}
