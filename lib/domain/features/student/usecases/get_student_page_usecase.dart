import '../entities/student.dart';
import '../repositories/student_repository.dart';

class GetStudentPageUseCase {
  GetStudentPageUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentPage> call({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStudentPage(
      schoolCode: schoolCode,
      code: code,
      firstName: firstName,
      lastName: lastName,
      status: status,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      search: search,
      page: page,
      size: size,
    );
  }
}
