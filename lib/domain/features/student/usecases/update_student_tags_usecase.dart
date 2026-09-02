import '../repositories/student_repository.dart';

/// Use case to update a student's tags.
class UpdateStudentTagsUseCase {
  UpdateStudentTagsUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) {
    return _repository.updateStudentTags(
      studentCode: studentCode,
      schoolCode: schoolCode,
      tagCodes: tagCodes,
    );
  }
}
