import 'package:wowcare/core/util/api_error_handler.dart';

import '../entities/activity_detail.dart';
import '../repositories/activity_repository.dart';

class GetActivityUseCase {
  GetActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<ActivityDetail> call({required String code}) async {
    try {
      return await _repository.getActivity(code: code);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
