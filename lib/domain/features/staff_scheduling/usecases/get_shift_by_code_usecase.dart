import '../entities/staff_shift.dart';
import '../repositories/staff_scheduling_repository.dart';

class GetShiftByCodeUseCase {
  GetShiftByCodeUseCase(this._repository);

  final StaffSchedulingRepository _repository;

  Future<StaffShiftEntity?> call(String shiftCode) {
    return _repository.getShiftByCode(shiftCode);
  }
}

