import '../entities/staff_overtime_profile.dart';
import '../repositories/attendance_v2_repository.dart';

/// Fetches one staff member's overtime profile for a date range.
class GetStaffOvertimeProfileUseCase {
  GetStaffOvertimeProfileUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<StaffOvertimeProfile> call({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getStaffProfile(
      staffCode: staffCode,
      staffName: staffName,
      from: from,
      to: to,
    );
  }
}
