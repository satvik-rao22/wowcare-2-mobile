import '../repositories/attendance_repository.dart';

/// Use case for fetching the current-day sign-in status for multiple staff members.
class GetStaffTodaySignInStatusMapUseCase {
  GetStaffTodaySignInStatusMapUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Map<String, String>> call({required List<String> staffCodes}) {
    return _repository.getStaffTodaySignInStatusMap(staffCodes);
  }
}
