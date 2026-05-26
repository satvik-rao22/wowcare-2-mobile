import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

class CreateStaffShiftUseCase {
  CreateStaffShiftUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<StaffShiftCreateResult> call(StaffShiftCreateRequest request) {
    return _repository.createStaffShift(request);
  }
}
