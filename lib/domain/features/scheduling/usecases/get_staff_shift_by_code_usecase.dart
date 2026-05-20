import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

/// `GET /api/v1/staff-shifts/{shiftCode}` — single-shift detail loader for the
/// View Shift screen.
class GetStaffShiftByCodeUseCase {
  GetStaffShiftByCodeUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<StaffShift> call(String shiftCode) {
    return _repository.getStaffShiftByCode(shiftCode);
  }
}
