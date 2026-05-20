import 'copy_shift_params.dart';
import 'copy_shift_response.dart';

abstract class StaffShiftRepository {
  Future<CopyShiftResponse> copyShift(CopyShiftParams params);
}
