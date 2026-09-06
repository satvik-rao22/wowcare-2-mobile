import '../entities/update_guardian_request.dart';
import '../repositories/student_repository.dart';

/// Use case to update a guardian's details for a student.
class UpdateGuardianUseCase {
  UpdateGuardianUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String code,
    required String studentCode,
    required UpdateGuardianRequest request,
  }) {
    return _repository.updateGuardian(
      code: code,
      studentCode: studentCode,
      request: request,
    );
  }
}
