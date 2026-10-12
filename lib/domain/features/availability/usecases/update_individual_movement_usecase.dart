import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

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
      return await AppEvents.track(
        AppEvent.availabilityMovementUpdate,
        () => _repository.updateIndividualMovement(
          id: id,
          movementType: movementType,
          fromClassroomCode: fromClassroomCode,
          toClassroomCode: toClassroomCode,
          movementDate: movementDate,
          comment: comment,
        ),
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

