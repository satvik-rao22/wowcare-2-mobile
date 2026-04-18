import 'package:wowcare/core/util/api_error_handler.dart';

import '../repositories/activity_repository.dart';

class CreateSharedActivitiesUseCase {
  CreateSharedActivitiesUseCase(this._repository);

  final ActivityRepository _repository;

  Future<List<Map<String, dynamic>>> call({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    required List<Map<String, dynamic>> attachments,
  }) async {
    try {
      return await _repository.createSharedActivities(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDate,
        description: description,
        attachments: attachments,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

