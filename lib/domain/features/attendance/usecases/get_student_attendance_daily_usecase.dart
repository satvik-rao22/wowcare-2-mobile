import '../entities/student_attendance_daily.dart';
import '../repositories/attendance_repository.dart';

class GetStudentAttendanceDailyUseCase {
  GetStudentAttendanceDailyUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceDailyPage> call({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStudentAttendanceDaily(
      attendanceDate: attendanceDate,
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      studentCodes: studentCodes,
      tagCodes: tagCodes,
      signInAtFilter: signInAtFilter,
      signOutAtFilter: signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked,
      search: search,
      page: page,
      size: size,
    );
  }
}
