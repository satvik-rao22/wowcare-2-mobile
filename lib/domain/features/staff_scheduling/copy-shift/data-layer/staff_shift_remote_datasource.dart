import '../domain/copy_shift_params.dart';
import '../domain/copy_shift_response.dart';

abstract class StaffShiftRemoteDataSource {
  Future<CopyShiftResponse> copyShift(CopyShiftParams params);
}
