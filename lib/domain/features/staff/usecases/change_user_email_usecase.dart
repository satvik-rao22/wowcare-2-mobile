import '../repositories/staff_repository.dart';

/// Use case to change the login email for a user.
class ChangeUserEmailUseCase {
  ChangeUserEmailUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  }) {
    return _repository.changeUserEmail(
      userCode: userCode,
      oldEmail: oldEmail,
      newEmail: newEmail,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
