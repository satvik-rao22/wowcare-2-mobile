import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Links siblings onto a newly created student (add-student flow only).
///
/// Returns the backend `message` field.
class AddStudentSiblingUseCase {
  AddStudentSiblingUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required List<String> siblingCodes,
  }) {
    return AppEvents.track(
      AppEvent.studentSiblingAdd,
      () => _repository.addStudentSibling(
        studentCode: studentCode,
        siblingCodes: siblingCodes,
      ),
      count: siblingCodes.length,
    );
  }
}
