import '../repositories/staff_repository.dart';

/// Use case to activate an organization admin.
class ActivateOrganizationAdminUseCase {
  ActivateOrganizationAdminUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String userCode,
    required String organizationCode,
  }) {
    return _repository.activateOrganizationAdmin(
      userCode: userCode,
      organizationCode: organizationCode,
    );
  }
}
