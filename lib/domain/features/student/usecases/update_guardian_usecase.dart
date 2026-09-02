import '../repositories/student_repository.dart';

/// Use case to update a guardian's details for a student.
class UpdateGuardianUseCase {
  UpdateGuardianUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String code,
    required String studentCode,
    required Map<String, dynamic> fields,
  }) {
    return _repository.updateGuardian(
      code: code,
      studentCode: studentCode,
      fields: fields,
    );
  }
}
