import '../entities/staff_shift_hours_entry.dart';
import '../repositories/staff_shift_repository.dart';

/// Loads per-staff hour totals via `POST /api/v1/staff-shifts/hours/range`.
class GetStaffShiftHoursRangeUseCase {
  GetStaffShiftHoursRangeUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<List<StaffShiftHoursEntry>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime startDate,
    required DateTime endDate,
    List<String> staffCodes = const <String>[],
  }) {
    return _repository.getStaffShiftHoursRange(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      startDate: startDate,
      endDate: endDate,
      staffCodes: staffCodes,
    );
  }
}
