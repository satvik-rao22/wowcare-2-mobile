import '../entities/holiday.dart';
import '../repositories/event_repository.dart';

class GetHolidaysUseCase {
  GetHolidaysUseCase(this._repository);

  final EventRepository _repository;

  Future<List<Holiday>> call() {
    return _repository.getHolidays();
  }
}
