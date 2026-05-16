import '../repositories/attendance_repository.dart';

/// Use case for fetching the current-day sign-in status for a staff member.
///
/// This is intentionally lightweight as it is used by small UI widgets
/// such as avatars and list tiles.
class GetStaffTodaySignInStatusUseCase {
  GetStaffTodaySignInStatusUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<String?> call({required String staffCode}) {
    return _repository.getStaffTodaySignInStatus(staffCode);
  }
}
