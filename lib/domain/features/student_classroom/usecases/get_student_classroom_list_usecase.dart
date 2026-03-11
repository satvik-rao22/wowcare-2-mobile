import '../entities/student_classroom_item.dart';
import '../repositories/student_classroom_repository.dart';

class GetStudentClassroomListUseCase {
  GetStudentClassroomListUseCase(this._repository);

  final StudentClassroomRepository _repository;

  Future<List<StudentClassroomItem>> call({
    required String schoolCode,
    required String classroomCode,
    List<String>? tagCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) {
    return _repository.getStudentClassroomList(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      tagCodes: tagCodes,
      status: status,
      attendanceStatus: attendanceStatus,
      refresh: refresh,
    );
  }
}


