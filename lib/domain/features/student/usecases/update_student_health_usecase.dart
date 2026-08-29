import '../entities/student_health.dart';
import '../repositories/student_repository.dart';

class UpdateStudentHealthUseCase {
  UpdateStudentHealthUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentHealth> call({
    required String studentCode,
    required Map<String, dynamic> body,
  }) {
    return _repository.updateStudentHealth(studentCode: studentCode, body: body);
  }
}
