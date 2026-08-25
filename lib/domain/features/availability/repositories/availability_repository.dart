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
  Future<String> deleteIndividualMovement({required int id});

  Future<IndividualMovement> getIndividualMovementById({required int id});

  Future<FutureAvailabilityGrid> getFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  });

  /// Triggers manual recomputation of future availability snapshots.
  /// Must be called before fetching data to ensure latest snapshots.
  Future<void> recomputeFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetches pending + overdue movement counts for the given school and date range.
  Future<({int pendingCount, int overdueCount})> getMovementStatusCounts({
    required String schoolCode,
    required String fromDate,
    required String toDate,
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

  /// Invalidates cached availability data for a school.
  ///
  /// Call this after any mutation (edit/delete/reject/confirm/recompute) so the
  /// next load/refresh never reuses stale cached snapshots.
  Future<void> invalidateAvailabilityCache({required String schoolCode});
}
