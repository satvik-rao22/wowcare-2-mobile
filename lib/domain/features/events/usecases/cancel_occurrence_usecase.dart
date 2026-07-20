import '../repositories/event_repository.dart';

class CancelOccurrenceUseCase {
  CancelOccurrenceUseCase(this._repository);

  final EventRepository _repository;

  /// Cancels a single occurrence with an optional [reason]; the rest of
  /// the series stays untouched.
  Future<void> call({
    required String eventCode,
    required String occurrenceCode,
    String reason = '',
  }) {
    return _repository.cancelOccurrence(
      eventCode: eventCode,
      occurrenceCode: occurrenceCode,
      reason: reason,
    );
  }
}
