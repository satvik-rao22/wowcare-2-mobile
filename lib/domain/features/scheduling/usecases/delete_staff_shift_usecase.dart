import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_shift_repository.dart';

/// `DELETE /api/v1/staff-shifts/{shiftCode}` — remove one shift occurrence.
class DeleteStaffShiftUseCase {
  DeleteStaffShiftUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<void> call({
    required String shiftCode,
    String? staffCode,
  }) {
    return AppEvents.track(
      AppEvent.schedulingShiftDelete,
      () => _repository.deleteStaffShift(
        shiftCode: shiftCode,
        staffCode: staffCode,
      ),
    );
  }
}
