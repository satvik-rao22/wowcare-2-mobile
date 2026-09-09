import '../entities/student_physical_exam.dart';
import '../repositories/student_repository.dart';

class GetStudentPhysicalExamsUseCase {
  GetStudentPhysicalExamsUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<StudentPhysicalExam>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) {
    return _repository.getStudentPhysicalExams(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
  }
}
