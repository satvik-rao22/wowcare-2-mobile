import '../entities/student_classroom_item.dart';
import '../repositories/student_classroom_repository.dart';

class GetStudentClassroomListUseCase {
  GetStudentClassroomListUseCase(this._repository);

  final StudentClassroomRepository _repository;

  Future<List<StudentClassroomItem>> call({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) {
    return _repository.getStudentClassroomList(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      firstName: firstName,
      lastName: lastName,
      search: search,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      status: status,
      attendanceStatus: attendanceStatus,
      refresh: refresh,
    );
  }
}


