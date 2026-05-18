import 'copy_shift_params.dart';
import 'copy_shift_response.dart';
import 'staff_shift_repository.dart';

class CopyShiftUseCase {
  final StaffShiftRepository repository;

  CopyShiftUseCase(this.repository);

  Future<CopyShiftResponse> call(CopyShiftParams params) {
    return repository.copyShift(params);
  }
}
