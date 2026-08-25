import '../entities/staff_profile.dart';
import '../repositories/staff_repository.dart';

class GetStaffProfileUseCase {
  GetStaffProfileUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffProfile> call({
    required String staffCode,
    bool forEditStaff = true,
    bool forceRefresh = false,
  }) {
    return _repository.getStaffProfile(
      staffCode: staffCode,
      forEditStaff: forEditStaff,
      forceRefresh: forceRefresh,
    );
  }
}
