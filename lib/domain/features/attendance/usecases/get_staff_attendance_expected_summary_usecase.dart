import '../entities/student_attendance_expected_summary.dart';
import '../repositories/attendance_repository.dart';

class GetStaffAttendanceExpectedSummaryUseCase {
  GetStaffAttendanceExpectedSummaryUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceExpectedSummary> call({String? classroomCode}) {
    return _repository.getStaffAttendanceExpectedSummary(
      classroomCode: classroomCode,
    );
  }
}
