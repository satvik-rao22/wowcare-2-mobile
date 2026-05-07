import 'package:wowcare/core/util/api_error_handler.dart';

import '../repositories/activity_repository.dart';

class RejectActivityUseCase {
  RejectActivityUseCase(this._repository);

  final ActivityRepository _repository;

  Future<String> call({required String code}) async {
    try {
      return await _repository.rejectActivity(code: code);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
