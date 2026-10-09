import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

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
    bool? napReminderEnabled,
    String? napReminderUserCode,
    String? napReminderRole,
    bool? requireAdminApproval,
    List<ActivityParameterValue> parameterValues = const [],
    List<ActivityAttachment> attachments = const [],
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.activityCreate,
        () => _repository.createActivity(
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
          napReminderEnabled: napReminderEnabled,
          napReminderUserCode: napReminderUserCode,
          napReminderRole: napReminderRole,
          requireAdminApproval: requireAdminApproval,
          parameterValues: parameterValues,
          attachments: attachments,
        ),
        count: studentCodes.length,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}


