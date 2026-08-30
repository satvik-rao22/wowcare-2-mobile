import '../repositories/student_repository.dart';

/// Use case to update a student's core profile details.
class UpdateStudentProfileUseCase {
  UpdateStudentProfileUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String code,
    required Map<String, dynamic> fields,
  }) {
    return _repository.updateStudentProfile(code: code, fields: fields);
  }
}
