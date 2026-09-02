import '../entities/student_health.dart';
import '../repositories/student_repository.dart';

class GetStudentHealthUseCase {
  GetStudentHealthUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentHealth> call({required String studentCode}) {
    return _repository.getStudentHealth(studentCode: studentCode);
  }
}
