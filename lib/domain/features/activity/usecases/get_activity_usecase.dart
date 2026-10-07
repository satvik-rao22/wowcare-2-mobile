import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/activity/entities/activity_detail.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class GetActivityUseCase {
  GetActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityDetail> call({
    required String code,
    bool asGuardian = false,
  }) async {
    try {
      return await _repository.getActivity(
        code: code,
        asGuardian: asGuardian,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
