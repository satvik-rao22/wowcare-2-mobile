import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class GetStaffListBySchoolUseCase {
  GetStaffListBySchoolUseCase(this._repository);

  final StaffRepository _repository;

  Future<List<StaffMember>> call({required String schoolCode}) {
    return _repository.getStaffListBySchool(schoolCode: schoolCode);
  }
}
