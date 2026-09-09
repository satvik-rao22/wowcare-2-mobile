import '../entities/student_regular_schedule_input.dart';
import '../repositories/student_repository.dart';

/// Use case to update a student's regular (weekly) schedule.
class UpdateStudentRegularSchedulesUseCase {
  UpdateStudentRegularSchedulesUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String schoolCode,
    required String studentCode,
    required List<StudentRegularScheduleInput> schedule,
  }) {
    return _repository.updateStudentRegularSchedules(
      schoolCode: schoolCode,
      studentCode: studentCode,
      schedule: schedule,
    );
  }
}
