import '../entities/staff_overtime_profile.dart';
import '../repositories/attendance_v2_repository.dart';

/// Loads the staff overtime overview (summary + per-day rollups) for a range.
class GetStaffOverviewUseCase {
  GetStaffOverviewUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<StaffOvertimeProfile> call({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getOverview(
      staffCode: staffCode,
      staffName: staffName,
      from: from,
      to: to,
    );
  }
}
