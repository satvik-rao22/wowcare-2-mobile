import '../entities/staff_profile_update.dart';
import '../repositories/staff_repository.dart';

/// Use case to update a staff member's core profile details.
class UpdateStaffProfileUseCase {
  UpdateStaffProfileUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required StaffProfileUpdate fields,
  }) {
    return _repository.updateStaffProfile(staffCode: staffCode, fields: fields);
  }
}
