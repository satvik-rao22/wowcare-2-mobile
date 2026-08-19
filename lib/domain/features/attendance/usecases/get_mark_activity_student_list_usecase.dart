import '../entities/student_attendance_custom.dart';
import '../repositories/attendance_repository.dart';

class GetMarkActivityStudentListUseCase {
  GetMarkActivityStudentListUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceCustomPage> call({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    int page = 0,
    int size = 200,
  }) {
    return _repository.getMarkActivityStudentList(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      page: page,
      size: size,
    );
  }
}
