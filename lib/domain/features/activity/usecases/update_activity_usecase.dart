import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class UpdateActivityUseCase {
  UpdateActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<String> call({
    required String code,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    List<ActivityParameterValue> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.activityUpdate,
        () => _repository.updateActivity(
          code: code,
          studentCodes: studentCodes,
          applyToStudentCodes: applyToStudentCodes,
          staffCode: staffCode,
          activityDate: activityDate,
          description: description,
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
