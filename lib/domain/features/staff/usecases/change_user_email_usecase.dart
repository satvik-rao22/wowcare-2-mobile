import '../repositories/staff_repository.dart';

/// Changes the login email for a user via
/// `POST /api/v1/users/{userCode}/email-change`. Lives on [StaffRepository]
/// (it's user-generic, keyed by userCode, not staffCode) but is reused as-is
/// by both the staff and guardian edit-profile flows.
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
