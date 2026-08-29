import '../entities/student_guardian.dart';
import '../repositories/student_repository.dart';

class GetStudentGuardiansUseCase {
  GetStudentGuardiansUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<StudentGuardian>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) {
    return _repository.getStudentGuardians(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }
}
