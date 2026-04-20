import '../repositories/student_repository.dart';

/// Use case to load all guardian/parent display names for a given school.
class GetGuardianNamesForSchoolUseCase {
  GetGuardianNamesForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<String>> call({
    required String schoolCode,
  }) {
    return _repository.getGuardianNamesForSchool(
      schoolCode: schoolCode,
    );
  }
}

