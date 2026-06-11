import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase {
  GetEventsUseCase(this._repository);

  final EventRepository _repository;

  Future<List<Event>> call() {
    return _repository.getEvents();
  }
}
