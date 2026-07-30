import '../entities/event.dart';
import '../repositories/event_repository.dart';

class UpdateEventUseCase {
  UpdateEventUseCase(this._repository);

  final EventRepository _repository;

  /// Updates the whole series, or — with [splitFromOccurrenceCode] —
  /// splits it at that occurrence (THIS_AND_FUTURE) so changes apply from
  /// that date onward; the returned event is the NEW series.
  Future<Event> call(Event event, {String splitFromOccurrenceCode = ''}) {
    return _repository.updateEvent(
      event,
      splitFromOccurrenceCode: splitFromOccurrenceCode,
    );
  }
}
