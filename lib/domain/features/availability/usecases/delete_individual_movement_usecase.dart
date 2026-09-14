import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class DeleteIndividualMovementUseCase {
  DeleteIndividualMovementUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<String> call({
    required int id,
  }) async {
    try {
      return await _repository.deleteIndividualMovement(id: id);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

