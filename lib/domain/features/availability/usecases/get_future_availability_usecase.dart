import 'package:wowcare/domain/features/availability/entities/future_availability.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class GetFutureAvailabilityUseCase {
  GetFutureAvailabilityUseCase(this._repository);

  final AvailabilityRepository _repository;

  Future<FutureAvailabilityGrid> call({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  }) {
    return _repository.getFutureAvailability(
      schoolCode: schoolCode,
      startDate: startDate,
      endDate: endDate,
      shift: shift,
    );
  }
}
