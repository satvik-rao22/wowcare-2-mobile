import '../repositories/student_repository.dart';

/// Loads a mapping of vaccine display names to backend vaccine codes (`VCC_*`) for a school.
class GetVaccineNameToCodeMapForSchoolUseCase {
  GetVaccineNameToCodeMapForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<Map<String, String>> call({
    required String schoolCode,
  }) {
    return _repository.getVaccineNameToCodeMapForSchool(
      schoolCode: schoolCode,
    );
  }
}
