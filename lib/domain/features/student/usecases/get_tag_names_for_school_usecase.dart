import '../repositories/student_repository.dart';

/// Use case to load all tag display names for a given school.
class GetTagNamesForSchoolUseCase {
  GetTagNamesForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<String>> call({required String schoolCode}) {
    return _repository.getTagNamesForSchool(schoolCode: schoolCode);
  }
}
