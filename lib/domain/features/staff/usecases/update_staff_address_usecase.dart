import 'package:wowcare/core/observability/app_events.dart';

import '../entities/staff_address_update.dart';
import '../repositories/staff_repository.dart';

/// Use case to update a staff member's address.
class UpdateStaffAddressUseCase {
  UpdateStaffAddressUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required StaffAddressUpdate fields,
  }) {
    return AppEvents.track(
      AppEvent.staffAddressUpdate,
      () =>
          _repository.updateStaffAddress(staffCode: staffCode, fields: fields),
    );
  }
}
