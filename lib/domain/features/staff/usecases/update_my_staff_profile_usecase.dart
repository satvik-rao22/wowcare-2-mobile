import '../entities/staff_my_profile_update.dart';
import '../repositories/staff_repository.dart';

/// Updates the *logged-in* staff member's own basic profile + address, via
/// `PATCH /api/v1/staff/staff/my-profile/{staffCode}`. Distinct from
/// [UpdateStaffProfileUseCase], which is for an admin editing someone else's
/// staff record.
class UpdateMyStaffProfileUseCase {
  UpdateMyStaffProfileUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required StaffMyProfileUpdate fields,
  }) {
    return _repository.updateMyProfile(staffCode: staffCode, fields: fields);
  }
}
