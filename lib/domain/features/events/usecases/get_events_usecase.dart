import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase {
  GetEventsUseCase(this._repository);

  final EventRepository _repository;

  /// Occurrence rows in the [from]..[to] window, one [Event] view per
  /// occurrence with roster and the caller's RSVP resolved via [partyCode].
  Future<List<Event>> call({
    required DateTime from,
    required DateTime to,
    String partyCode = '',
  }) {
    return _repository.getEvents(from: from, to: to, partyCode: partyCode);
  }

  /// One page (infinite scroll on grid/list views).
  Future<(List<Event>, bool)> page({
    required DateTime from,
    required DateTime to,
    required int page,
    int size = 10,
    String partyCode = '',
  }) {
    return _repository.getEventsPage(
      from: from,
      to: to,
      page: page,
      size: size,
      partyCode: partyCode,
    );
  }
}
