import '../repositories/student_repository.dart';

/// Use case to load a mapping of tag display names to tag codes for a school.
class GetTagNameCodeMapForSchoolUseCase {
  GetTagNameCodeMapForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<Map<String, String>> call({
    required String schoolCode,
  }) {
    return _repository.getTagNameCodeMapForSchool(
      schoolCode: schoolCode,
    );
  }
}


