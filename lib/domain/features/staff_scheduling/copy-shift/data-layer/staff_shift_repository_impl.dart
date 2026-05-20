import '../domain/copy_shift_params.dart';
import '../domain/copy_shift_response.dart';
import '../domain/staff_shift_repository.dart';
import 'staff_shift_remote_datasource.dart';

class StaffShiftRepositoryImpl implements StaffShiftRepository {
  final StaffShiftRemoteDataSource remoteDataSource;

  StaffShiftRepositoryImpl(this.remoteDataSource);

  @override
  Future<CopyShiftResponse> copyShift(CopyShiftParams params) {
    return remoteDataSource.copyShift(params);
  }
}
