import '../repositories/staff_repository.dart';

/// Use case to deactivate a school user.
class DeactivateSchoolUserUseCase {
  DeactivateSchoolUserUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    return _repository.deactivateSchoolUser(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      role: role,
    );
  }
}
