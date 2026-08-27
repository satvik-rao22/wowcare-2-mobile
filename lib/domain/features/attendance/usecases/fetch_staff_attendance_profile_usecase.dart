import '../entities/staff_attendance_profile_response.dart';
import '../repositories/attendance_repository.dart';

/// Loads the staff attendance profile (present-day summary + records).
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: the raw response is returned as-is and any thrown error is
/// propagated unchanged.
class FetchStaffAttendanceProfileUseCase {
  const FetchStaffAttendanceProfileUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StaffAttendanceProfileResponse?> call({
    required Map<String, dynamic> queryParameters,
  }) {
    return _repository.fetchStaffAttendanceProfile(
      queryParameters: queryParameters,
    );
  }
}
