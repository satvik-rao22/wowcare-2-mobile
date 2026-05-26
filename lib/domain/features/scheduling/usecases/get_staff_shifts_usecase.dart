import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

class GetStaffShiftsUseCase {
  GetStaffShiftsUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<List<StaffShift>> call({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    return _repository.getStaffShifts(
      staffCode: staffCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
