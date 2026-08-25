import 'package:wowcare/core/util/api_error_handler.dart';

import '../entities/individual_movement.dart';
import '../repositories/availability_repository.dart';

class UpdateIndividualMovementUseCase {
  UpdateIndividualMovementUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<String> call({
    required int id,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) async {
    try {
      return await _repository.updateIndividualMovement(
        id: id,
        movementType: movementType,
        fromClassroomCode: fromClassroomCode,
        toClassroomCode: toClassroomCode,
        movementDate: movementDate,
        comment: comment,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
