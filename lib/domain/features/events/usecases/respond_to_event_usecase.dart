import '../entities/event.dart';
import '../repositories/event_repository.dart';

class RespondToEventUseCase {
  RespondToEventUseCase(this._repository);

  final EventRepository _repository;

  /// Upserts [partyCode]'s RSVP on one occurrence (the occurrence code
  /// comes with every occurrence-based event view — no lookup needed).
  Future<void> call({
    required String eventCode,
    required String occurrenceCode,
    required String partyCode,
    required String partyType,
    required EventRsvpStatus status,
  }) {
    return _repository.respondToOccurrence(
      eventCode: eventCode,
      occurrenceCode: occurrenceCode,
      partyCode: partyCode,
      partyType: partyType,
      status: status,
    );
  }
}
