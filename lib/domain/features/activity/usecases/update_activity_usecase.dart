import 'package:wowcare/core/util/api_error_handler.dart';

import '../repositories/activity_repository.dart';

class UpdateActivityUseCase {
  UpdateActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<String> call({
    required String code,
    required String staffCode,
    required String activityDate,
    required String description,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      return await _repository.updateActivity(
        code: code,
        staffCode: staffCode,
        activityDate: activityDate,
        description: description,
        parameterValues: parameterValues,
        attachments: attachments,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
