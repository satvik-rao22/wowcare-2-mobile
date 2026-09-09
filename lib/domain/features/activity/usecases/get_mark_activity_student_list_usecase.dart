import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class GetMarkActivityStudentListUseCase {
  GetMarkActivityStudentListUseCase(this._repository);

  final ActivityRepository _repository;

  Future<List<StudentAttendanceCustomItem>> call({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    int page = 0,
    int size = 200,
    required String selectedClassroomCode,
  }) {
    return _repository.getMarkActivityStudentList(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      page: page,
      size: size,
      selectedClassroomCode: selectedClassroomCode,
    );
  }
}
