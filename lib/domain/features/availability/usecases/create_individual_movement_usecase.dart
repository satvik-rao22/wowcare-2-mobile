import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class CreateIndividualMovementUseCase {
  CreateIndividualMovementUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<String> call({
    required String schoolCode,
    required String organizationCode,
    required String studentCode,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.availabilityMovementCreate,
        () => _repository.createIndividualMovement(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          studentCode: studentCode,
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
