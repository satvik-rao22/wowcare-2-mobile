import '../repositories/attendance_repository.dart';

/// Use case for fetching the current-day sign-in status for a student.
///
/// This is intentionally lightweight as it is used by small UI widgets
/// such as avatars and list tiles.
class GetStudentTodaySignInStatusUseCase {
  GetStudentTodaySignInStatusUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<String?> call({required String studentCode}) {
    return _repository.getStudentTodaySignInStatus(studentCode);
  }
}
