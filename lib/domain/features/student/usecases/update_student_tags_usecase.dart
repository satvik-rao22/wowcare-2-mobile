import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Use case to update a student's tags.
class UpdateStudentTagsUseCase {
  UpdateStudentTagsUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) {
    return AppEvents.track(
      AppEvent.studentTagsUpdate,
      () => _repository.updateStudentTags(
        studentCode: studentCode,
        schoolCode: schoolCode,
        tagCodes: tagCodes,
      ),
      count: tagCodes.length,
    );
  }
}
