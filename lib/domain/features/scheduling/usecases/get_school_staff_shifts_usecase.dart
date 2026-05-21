import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

/// School-wide shifts loader for the classroom scheduling table — calls
/// `GET /api/v1/staff/staff-shifts?schoolCode&organizationCode&dateFrom&dateTo`
/// (no `staffCode`). The scheduling screen passes today's date for both
/// `dateFrom` and `dateTo` since the UI doesn't expose a date range.
class GetSchoolStaffShiftsUseCase {
  GetSchoolStaffShiftsUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<List<StaffShift>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    return _repository.getSchoolStaffShifts(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
