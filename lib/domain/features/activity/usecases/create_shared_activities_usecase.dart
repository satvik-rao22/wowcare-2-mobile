import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/entities/activity_shared_card_result.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class CreateSharedActivitiesUseCase {
  CreateSharedActivitiesUseCase(this._repository);

  final ActivityRepository _repository;

  Future<List<ActivitySharedCardResult>> call({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? requireAdminApproval,
    required List<ActivityAttachment> attachments,
    List<ActivityParameterValue> parameterValues = const [],
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.activityShare,
        () => _repository.createSharedActivities(
          activityTypeCode: activityTypeCode,
          classroomCode: classroomCode,
          studentCodes: studentCodes,
          staffCode: staffCode,
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          activityDate: activityDate,
          description: description,
          requireAdminApproval: requireAdminApproval,
          attachments: attachments,
          parameterValues: parameterValues,
        ),
        count: studentCodes.length,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

