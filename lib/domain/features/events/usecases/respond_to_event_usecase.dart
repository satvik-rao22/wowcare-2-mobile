import '../entities/event.dart';
import '../repositories/event_repository.dart';

class RespondToEventUseCase {
  RespondToEventUseCase(this._repository);

  final EventRepository _repository;

  Future<Event> call({required String eventCode, required EventRsvp rsvp}) {
    return _repository.respondToEvent(eventCode: eventCode, rsvp: rsvp);
  }
}
