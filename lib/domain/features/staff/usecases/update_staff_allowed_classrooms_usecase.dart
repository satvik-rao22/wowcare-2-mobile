import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_repository.dart';

/// Use case to update a staff member's allowed classrooms.
class UpdateStaffAllowedClassroomsUseCase {
  UpdateStaffAllowedClassroomsUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required List<String> classroomCodes,
  }) {
    return AppEvents.track(
      AppEvent.staffAllowedClassroomsUpdate,
      () => _repository.updateStaffAllowedClassrooms(
        staffCode: staffCode,
        classroomCodes: classroomCodes,
      ),
    );
  }
}
