import '../entities/student_attendance_expected_summary.dart';
import '../repositories/attendance_repository.dart';

class GetStudentAttendanceExpectedSummaryUseCase {
  GetStudentAttendanceExpectedSummaryUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceExpectedSummary> call({
    String? classroomCode,
    bool schoolWide = false,
    bool forceRefresh = false,
  }) {
    return _repository.getStudentAttendanceExpectedSummary(
      classroomCode: classroomCode,
      schoolWide: schoolWide,
      forceRefresh: forceRefresh,
    );
  }
}

