import '../entities/student_attendance_daily.dart';
import '../repositories/attendance_repository.dart';

class GetStudentAttendanceDailyUseCase {
  GetStudentAttendanceDailyUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceDailyPage> call({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStudentAttendanceDaily(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
    );
  }
}
