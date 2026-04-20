import '../repositories/attendance_repository.dart';

/// Use case for fetching the current-day sign-in status for multiple students.
class GetStudentTodaySignInStatusMapUseCase {
  GetStudentTodaySignInStatusMapUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Map<String, String>> call({required List<String> studentCodes}) {
    return _repository.getStudentTodaySignInStatusMap(studentCodes);
  }
}

