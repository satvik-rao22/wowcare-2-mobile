import '../entities/student_health.dart';
import '../entities/student_health_update_request.dart';
import '../repositories/student_repository.dart';

class UpdateStudentHealthUseCase {
  UpdateStudentHealthUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentHealth> call({
    required String studentCode,
    required StudentHealthUpdateRequest request,
  }) {
    return _repository.updateStudentHealth(
      studentCode: studentCode,
      request: request,
    );
  }
}
