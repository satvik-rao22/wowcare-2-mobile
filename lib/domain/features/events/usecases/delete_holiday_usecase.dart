import '../repositories/event_repository.dart';

class DeleteHolidayUseCase {
  DeleteHolidayUseCase(this._repository);

  final EventRepository _repository;

  Future<void> call(String code) {
    return _repository.deleteHoliday(code);
  }
}
