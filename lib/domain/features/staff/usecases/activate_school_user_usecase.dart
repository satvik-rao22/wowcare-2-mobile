import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_repository.dart';

/// Use case to activate a school user.
class ActivateSchoolUserUseCase {
  ActivateSchoolUserUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    return AppEvents.track(
      AppEvent.staffActivate,
      () => _repository.activateSchoolUser(
        userCode: userCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        role: role,
      ),
    );
  }
}
