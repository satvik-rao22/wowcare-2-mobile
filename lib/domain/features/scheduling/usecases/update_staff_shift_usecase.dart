import 'package:wowcare/core/observability/app_events.dart';

import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

/// `PUT /api/v1/staff-shifts/{shiftCode}` — update a single shift occurrence.
class UpdateStaffShiftUseCase {
  UpdateStaffShiftUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<StaffShift> call(StaffShiftUpdateRequest request) {
    return AppEvents.track(
      AppEvent.schedulingShiftUpdate,
      () => _repository.updateStaffShift(request),
    );
  }
}
