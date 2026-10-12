import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_shift_repository.dart';

class PublishStaffShiftsUseCase {
  PublishStaffShiftsUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<void> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateRangeStart,
    required bool publishAll,
    required bool publishAllStaff,
    DateTime? publishUntilDate,
    List<String> selectedStaffCodes = const <String>[],
  }) {
    return AppEvents.track(
      AppEvent.schedulingShiftPublish,
      () => _repository.publishStaffShifts(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateRangeStart: dateRangeStart,
        publishAll: publishAll,
        publishAllStaff: publishAllStaff,
        publishUntilDate: publishUntilDate,
        selectedStaffCodes: selectedStaffCodes,
      ),
    );
  }
}
