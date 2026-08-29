import '../entities/student_pickup.dart';
import '../repositories/student_repository.dart';

class GetStudentPickupsUseCase {
  GetStudentPickupsUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<StudentPickup>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) {
    return _repository.getStudentPickups(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }
}
