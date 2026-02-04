import '../entities/staff_count.dart';
import '../repositories/staff_repository.dart';

class GetStaffCountUseCase {
  GetStaffCountUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffCount> call({
    required String schoolCode,
  }) {
    return _repository.getStaffCount(schoolCode: schoolCode);
  }
}


