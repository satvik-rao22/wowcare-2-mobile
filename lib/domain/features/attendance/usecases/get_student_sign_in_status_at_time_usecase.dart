import '../repositories/attendance_repository.dart';

/// Use case for the classroom-scoped "at time" student sign-in status used by
/// the activity attendance-window validator.
class GetStudentSignInStatusAtTimeUseCase {
  GetStudentSignInStatusAtTimeUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Map<String, bool>> call({
    required String classroomCode,
    required List<String> studentCodes,
    required DateTime instantUtc,
  }) {
    return _repository.getStudentSignInStatusAtTime(
      classroomCode: classroomCode,
      studentCodes: studentCodes,
      instantUtc: instantUtc,
    );
  }
}
