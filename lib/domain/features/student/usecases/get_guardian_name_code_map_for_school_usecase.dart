import '../repositories/student_repository.dart';

/// Use case to load a mapping of guardian display names to guardian codes
/// for a given school.
class GetGuardianNameCodeMapForSchoolUseCase {
  GetGuardianNameCodeMapForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<Map<String, String>> call({required String schoolCode}) {
    return _repository.getGuardianNameCodeMapForSchool(schoolCode: schoolCode);
  }
}
