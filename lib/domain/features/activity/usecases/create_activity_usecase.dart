import 'package:wowcare/core/util/api_error_handler.dart';

import '../repositories/activity_repository.dart';

class CreateActivityUseCase {
  CreateActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<String> call({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? napStart,
    bool? napEnd,
    bool? requireAdminApproval,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      return await _repository.createActivity(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDate,
        description: description,
        napStart: napStart,
        napEnd: napEnd,
        requireAdminApproval: requireAdminApproval,
        parameterValues: parameterValues,
        attachments: attachments,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}


