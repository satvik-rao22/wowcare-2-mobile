import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';
import 'package:wowcare/domain/features/activity/entities/activity_upload_session.dart';

class CreateActivityUploadSessionsUseCase {
  CreateActivityUploadSessionsUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityUploadSession> call({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
  }) {
    return _repository.createActivityUploadSessions(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      activityTypeCode: activityTypeCode,
      bindingMode: bindingMode,
      studentCodes: studentCodes,
    );
  }
}

