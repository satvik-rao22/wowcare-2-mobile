import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Use case to update a student's siblings.
class UpdateStudentSiblingsUseCase {
  UpdateStudentSiblingsUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required List<String> siblingCodes,
  }) {
    return AppEvents.track(
      AppEvent.studentSiblingsUpdate,
      () => _repository.updateStudentSiblings(
        studentCode: studentCode,
        siblingCodes: siblingCodes,
      ),
      count: siblingCodes.length,
    );
  }
}
