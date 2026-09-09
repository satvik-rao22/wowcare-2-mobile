import '../repositories/attendance_repository.dart';

/// Use case for the classroom-scoped "at time" staff sign-in status used by
/// the activity attendance-window validator.
class GetStaffSignInStatusAtTimeUseCase {
  GetStaffSignInStatusAtTimeUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Map<String, bool>> call({
    required String classroomCode,
    required List<String> staffCodes,
    required DateTime instantUtc,
  }) {
    return _repository.getStaffSignInStatusAtTime(
      classroomCode: classroomCode,
      staffCodes: staffCodes,
      instantUtc: instantUtc,
    );
  }
}
