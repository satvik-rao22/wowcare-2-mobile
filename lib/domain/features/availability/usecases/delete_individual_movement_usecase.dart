import 'package:wowcare/core/util/api_error_handler.dart';

import '../repositories/availability_repository.dart';

class DeleteIndividualMovementUseCase {
  DeleteIndividualMovementUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<String> call({required int id}) async {
    try {
      return await _repository.deleteIndividualMovement(id: id);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
