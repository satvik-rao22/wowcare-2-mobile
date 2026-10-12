import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/staff_repository.dart';

/// Use case to deactivate an organization admin.
class DeactivateOrganizationAdminUseCase {
  DeactivateOrganizationAdminUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String userCode,
    required String organizationCode,
  }) {
    return AppEvents.track(
      AppEvent.staffOrgAdminDeactivate,
      () => _repository.deactivateOrganizationAdmin(
        userCode: userCode,
        organizationCode: organizationCode,
      ),
    );
  }
}
