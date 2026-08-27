import '../entities/student_attendance_profile_absent_toggle_response.dart';
import '../repositories/attendance_repository.dart';

/// Loads the student attendance profile absent-toggle list.
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: the raw response is returned as-is and any thrown error is
/// propagated unchanged.
class FetchStudentAttendanceProfileAbsentToggleUseCase {
  const FetchStudentAttendanceProfileAbsentToggleUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceProfileAbsentToggleResponse?> call({
    required Map<String, dynamic> queryParameters,
  }) {
    return _repository.fetchStudentAttendanceProfileAbsentToggle(
      queryParameters: queryParameters,
    );
  }
}
