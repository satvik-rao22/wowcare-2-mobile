import '../repositories/event_repository.dart';

class DeleteEventUseCase {
  DeleteEventUseCase(this._repository);

  final EventRepository _repository;

  /// Deletes the whole series, or — with [fromOccurrenceCode] — cancels
  /// from that occurrence to the end (THIS_AND_FUTURE), keeping earlier
  /// occurrences intact.
  Future<void> call(String code, {String fromOccurrenceCode = ''}) {
    return _repository.deleteEvent(code, fromOccurrenceCode: fromOccurrenceCode);
  }
}
