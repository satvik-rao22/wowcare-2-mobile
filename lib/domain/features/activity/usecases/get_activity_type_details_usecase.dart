import 'package:wowcare/core/util/api_error_handler.dart';

import '../entities/activity_type_details.dart';
import '../repositories/activity_repository.dart';

class GetActivityTypeDetailsUseCase {
  GetActivityTypeDetailsUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityTypeDetails> call({required String code}) async {
    try {
      return await _repository.getActivityTypeDetails(code: code);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
