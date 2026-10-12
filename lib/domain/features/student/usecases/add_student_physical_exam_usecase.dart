import 'package:wowcare/core/observability/app_events.dart';

import '../entities/student_physical_exam.dart';
import '../repositories/student_repository.dart';

class AddStudentPhysicalExamUseCase {
  AddStudentPhysicalExamUseCase(this._repository);

  final StudentRepository _repository;

  Future<StudentPhysicalExam> call({
    required String studentCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) {
    return AppEvents.track(
      AppEvent.studentPhysicalExamAdd,
      () => _repository.addStudentPhysicalExam(
        studentCode: studentCode,
        examDate: examDate,
        status: status,
        notes: notes,
      ),
    );
  }
}
