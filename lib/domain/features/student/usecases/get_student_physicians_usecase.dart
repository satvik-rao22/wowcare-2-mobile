import '../entities/student_physician.dart';
import '../repositories/student_repository.dart';

class GetStudentPhysiciansUseCase {
  GetStudentPhysiciansUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<StudentPhysician>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) {
    return _repository.getStudentPhysicians(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }
}
