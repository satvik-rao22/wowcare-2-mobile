import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/entities/activity_type_details.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class GetActivityTypeDetailsUseCase {
  GetActivityTypeDetailsUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityTypeDetails> call({
    required String code,
  }) async {
    try {
      return await _repository.getActivityTypeDetails(code: code);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}


