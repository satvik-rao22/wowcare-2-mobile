import 'package:wowcare/core/util/api_error_handler.dart';

import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class GetIndividualMovementByIdUseCase {
  GetIndividualMovementByIdUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<IndividualMovement> call({required int id}) async {
    try {
      return await _repository.getIndividualMovementById(id: id);
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
