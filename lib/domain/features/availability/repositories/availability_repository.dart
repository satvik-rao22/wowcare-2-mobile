import '../entities/individual_movement_board.dart';
import '../entities/individual_movement.dart';
import '../entities/future_availability.dart';

abstract class AvailabilityRepository {
  Future<IndividualMovementBoard> getIndividualMovements({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  });

  Future<String> transitionIndividualMovementStatus({
    required int id,
    required IndividualMovementWorkflowStatus status,
    String? comment,
    DateTime? newMovementDate,
  });

  Future<String> createIndividualMovement({
    required String schoolCode,
    required String organizationCode,
    required String studentCode,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  });

  Future<String> updateIndividualMovement({
    required int id,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  });

  /// Soft-delete a movement (API allows only REJECTED items).
  Future<String> deleteIndividualMovement({
    required int id,
  });

  Future<IndividualMovement> getIndividualMovementById({
    required int id,
  });

  Future<FutureAvailabilityGrid> getFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  });
}

abstract class AvailabilityRepositoryWithCache {
  Future<IndividualMovementBoard?> loadCachedIndividualMovements({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  });

  Future<FutureAvailabilityGrid?> loadCachedFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  });
}
