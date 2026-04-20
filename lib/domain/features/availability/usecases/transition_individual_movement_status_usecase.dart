import 'package:wowcare/core/util/api_error_handler.dart';

import '../entities/individual_movement.dart';
import '../repositories/availability_repository.dart';

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
      return await _repository.transitionIndividualMovementStatus(
        id: id,
        status: status,
        comment: comment,
        newMovementDate: newMovementDate,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
