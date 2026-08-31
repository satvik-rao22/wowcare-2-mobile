import '../repositories/staff_repository.dart';

/// Use case to update a staff member's address.
class UpdateStaffAddressUseCase {
  UpdateStaffAddressUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required Map<String, dynamic> fields,
  }) {
    return _repository.updateStaffAddress(staffCode: staffCode, fields: fields);
  }
}
