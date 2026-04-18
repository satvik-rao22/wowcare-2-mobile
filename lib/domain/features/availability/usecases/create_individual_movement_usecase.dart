import 'package:wowcare/core/util/api_error_handler.dart';

import '../entities/individual_movement.dart';
import '../repositories/availability_repository.dart';

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
      return await _repository.createIndividualMovement(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        studentCode: studentCode,
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
