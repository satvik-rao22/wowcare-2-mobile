import '../entities/event.dart';
import '../repositories/event_repository.dart';

class UpdateEventUseCase {
  UpdateEventUseCase(this._repository);

  final EventRepository _repository;

  Future<Event> call(Event event) {
    return _repository.updateEvent(event);
  }
}
