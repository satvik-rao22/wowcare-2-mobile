import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_repository.dart';

/// Use case to update a staff member's primary classroom.
class UpdateStaffPrimaryClassroomUseCase {
  UpdateStaffPrimaryClassroomUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required String classroomCode,
  }) {
    return AppEvents.track(
      AppEvent.staffPrimaryClassroomUpdate,
      () => _repository.updateStaffPrimaryClassroom(
        staffCode: staffCode,
        classroomCode: classroomCode,
      ),
    );
  }
}
