import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class GetIndividualMovementsUseCase {
  GetIndividualMovementsUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<IndividualMovementBoard> call({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) {
    return _repository.getIndividualMovements(
      schoolCode: schoolCode,
      studentCodes: studentCodes,
      fromClassroomCodes: fromClassroomCodes,
      toClassroomCodes: toClassroomCodes,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
    );
  }
}
