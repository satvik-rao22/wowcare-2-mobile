import '../repositories/attendance_v2_repository.dart';

/// Triggers the server-side overtime recompute for a staff member's range.
/// Run before reading the overview (entry, date change, pull-to-refresh).
class CalculateOvertimeUseCase {
  CalculateOvertimeUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<void> call({
    required String staffCode,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.calculate(staffCode: staffCode, from: from, to: to);
  }
}
