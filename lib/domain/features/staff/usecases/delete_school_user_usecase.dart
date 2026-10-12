import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_repository.dart';

/// Use case to permanently delete a (deactivated) school user.
class DeleteSchoolUserUseCase {
  DeleteSchoolUserUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    return AppEvents.track(
      AppEvent.staffDelete,
      () => _repository.deleteSchoolUser(
        userCode: userCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        role: role,
      ),
    );
  }
}
