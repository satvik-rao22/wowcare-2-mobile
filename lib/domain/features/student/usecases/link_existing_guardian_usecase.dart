import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Links an existing guardian to a student.
///
/// Returns the backend `message` field.
class LinkExistingGuardianUseCase {
  LinkExistingGuardianUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  }) {
    return AppEvents.track(
      AppEvent.guardianLink,
      () => _repository.linkExistingGuardian(
        guardianCode: guardianCode,
        studentCode: studentCode,
        relation: relation,
        relationDescription: relationDescription,
      ),
    );
  }
}
