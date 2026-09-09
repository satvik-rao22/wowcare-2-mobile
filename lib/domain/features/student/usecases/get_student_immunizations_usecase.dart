import '../entities/student_immunization.dart';
import '../repositories/student_repository.dart';

class GetStudentImmunizationsUseCase {
  GetStudentImmunizationsUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<StudentImmunization>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) {
    return _repository.getStudentImmunizations(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }
}
