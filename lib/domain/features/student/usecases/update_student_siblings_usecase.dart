import '../repositories/student_repository.dart';

/// Use case to update a student's siblings.
class UpdateStudentSiblingsUseCase {
  UpdateStudentSiblingsUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required List<String> siblingCodes,
  }) {
    return _repository.updateStudentSiblings(
      studentCode: studentCode,
      siblingCodes: siblingCodes,
    );
  }
}
