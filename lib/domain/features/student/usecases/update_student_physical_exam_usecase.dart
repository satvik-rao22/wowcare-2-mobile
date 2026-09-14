import '../entities/student_physical_exam.dart';
import '../repositories/student_repository.dart';

class UpdateStudentPhysicalExamUseCase {
  UpdateStudentPhysicalExamUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentPhysicalExam> call({
    required String studentCode,
    required String examCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) {
    return _repository.updateStudentPhysicalExam(
      studentCode: studentCode,
      examCode: examCode,
      examDate: examDate,
      status: status,
      notes: notes,
    );
  }
}
