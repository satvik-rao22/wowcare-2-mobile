import '../repositories/student_repository.dart';

/// Use case to fetch student counts (active, upcoming, enrolled) for a school.
class GetStudentCountsUseCase {
  GetStudentCountsUseCase(this._repository);

  final StudentRepository _repository;

  Future<Map<String, int>> call({required String schoolCode}) {
    return _repository.getStudentCounts(schoolCode: schoolCode);
  }
}
