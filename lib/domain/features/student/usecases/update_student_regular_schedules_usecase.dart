import '../repositories/student_repository.dart';

/// Updates a student's regular schedule (add-student wizard, Step 3 data).
///
/// Returns the backend `message` field.
class UpdateStudentRegularSchedulesUseCase {
  UpdateStudentRegularSchedulesUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String schoolCode,
    required String studentCode,
    required List<Map<String, dynamic>> schedule,
  }) {
    return _repository.updateStudentRegularSchedules(
      schoolCode: schoolCode,
      studentCode: studentCode,
      schedule: schedule,
    );
  }
}
