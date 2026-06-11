import '../entities/holiday.dart';
import '../repositories/event_repository.dart';

class SaveHolidayUseCase {
  SaveHolidayUseCase(this._repository);

  final EventRepository _repository;

  Future<Holiday> call(Holiday holiday) {
    return _repository.saveHoliday(holiday);
  }
}
