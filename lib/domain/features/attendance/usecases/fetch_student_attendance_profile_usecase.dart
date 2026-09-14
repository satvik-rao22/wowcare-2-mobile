import '../entities/attendance_profile_query.dart';
import '../entities/student_attendance_profile_response.dart';
import '../repositories/attendance_repository.dart';

/// Loads the student attendance profile (present-day summary + records).
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: the raw response is returned as-is and any thrown error is
/// propagated unchanged.
class FetchStudentAttendanceProfileUseCase {
  const FetchStudentAttendanceProfileUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceProfileResponse?> call({
    required AttendanceProfileQuery query,
  }) {
    return _repository.fetchStudentAttendanceProfile(query: query);
  }
}
