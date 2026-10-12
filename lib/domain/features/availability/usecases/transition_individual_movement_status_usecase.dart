import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class TransitionIndividualMovementStatusUseCase {
  TransitionIndividualMovementStatusUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<String> call({
    required int id,
    required IndividualMovementWorkflowStatus status,
    String? comment,
    DateTime? newMovementDate,
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.availabilityMovementStatusChange,
        () => _repository.transitionIndividualMovementStatus(
          id: id,
          status: status,
          comment: comment,
          newMovementDate: newMovementDate,
        ),
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
