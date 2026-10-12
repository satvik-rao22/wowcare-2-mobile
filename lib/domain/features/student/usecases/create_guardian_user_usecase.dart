import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Creates or links a guardian user to a student.
///
/// Returns the backend `message` and the newly created `guardianCode`.
class CreateGuardianUserUseCase {
  CreateGuardianUserUseCase(this._repository);

  final StudentRepository _repository;

  Future<({String message, String? guardianCode})> call({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
  }) {
    return AppEvents.track(
      AppEvent.guardianCreate,
      () => _repository.createGuardianUser(
        schoolCode: schoolCode,
        studentCode: studentCode,
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobile: mobile,
        relationToStudent: relationToStudent,
        primaryContact: primaryContact,
        legalCustody: legalCustody,
        profilePhotoUrl: profilePhotoUrl,
        userCode: userCode,
        organizationCode: organizationCode,
      ),
    );
  }
}
