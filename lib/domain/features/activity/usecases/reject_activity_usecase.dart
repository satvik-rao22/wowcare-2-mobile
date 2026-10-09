import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class RejectActivityUseCase {
  RejectActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<String> call({required String code}) async {
    try {
      return await AppEvents.track(
        AppEvent.activityReject,
        () => _repository.rejectActivity(code: code),
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
