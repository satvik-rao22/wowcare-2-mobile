import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventByCodeUseCase {
  GetEventByCodeUseCase(this._repository);

  final EventRepository _repository;

  /// Full series event (audience selectors + recurrence rule) — the edit
  /// form needs it because occurrence rows don't carry the rrule.
  Future<Event?> call(String code) => _repository.getEventByCode(code);
}
