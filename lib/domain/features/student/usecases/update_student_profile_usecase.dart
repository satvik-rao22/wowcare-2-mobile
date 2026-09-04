import '../entities/update_student_profile_request.dart';
import '../repositories/student_repository.dart';

/// Use case to update a student's core profile details.
class UpdateStudentProfileUseCase {
  UpdateStudentProfileUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String code,
    required UpdateStudentProfileRequest request,
  }) {
    return _repository.updateStudentProfile(
      code: code,
      request: request,
    );
  }
}
