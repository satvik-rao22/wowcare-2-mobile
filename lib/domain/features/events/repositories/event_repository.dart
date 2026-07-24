import '../entities/calendar_feed_item.dart';
import '../entities/event.dart';
import '../entities/holiday.dart';

abstract class EventRepository {
  /// Occurrence-based read: every occurrence in the [from]..[to] window as
  /// an [Event] view (one per occurrence, with roster + myRsvp resolved
  /// via [partyCode]).
  Future<List<Event>> getEvents({
    required DateTime from,
    required DateTime to,
    String partyCode,
  });

  /// One page of occurrence rows for infinite scrolling; returns the rows
  /// and whether more pages exist.
  Future<(List<Event>, bool)> getEventsPage({
    required DateTime from,
    required DateTime to,
    required int page,
    int size,
    String partyCode,
  });

  /// Unified calendar feed (events + tasks + holidays) for a window.
  Future<List<CalendarFeedItem>> getCalendarFeed({
    required DateTime from,
    required DateTime to,
    required String scope,
    String partyCode,
  });

  Future<Event?> getEventByCode(String code);

  Future<Event> createEvent(Event event);

  /// Updates the series (scope ALL); with [splitFromOccurrenceCode] the
  /// series splits at that occurrence (THIS_AND_FUTURE) and the returned
  /// event is the NEW series covering this date onward.
  Future<Event> updateEvent(Event event, {String splitFromOccurrenceCode});

  /// Deletes the series (scope ALL); with [fromOccurrenceCode] only this
  /// occurrence and later ones are cancelled (THIS_AND_FUTURE).
  Future<void> deleteEvent(String code, {String fromOccurrenceCode});

  /// Upserts [partyCode]'s RSVP on one occurrence (RSVPs are recorded
  /// per-occurrence). [partyType] is STAFF or PARENT — students never RSVP.
  Future<void> respondToOccurrence({
    required String eventCode,
    required String occurrenceCode,
    required String partyCode,
    required String partyType,
    required EventRsvpStatus status,
  });

  /// Overrides one occurrence (scope THIS_ONLY): name, description, date,
  /// times.
  Future<void> updateOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String? overrideName,
    String? overrideDescription,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  });

  /// Cancels one occurrence with an optional [reason].
  Future<void> cancelOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String reason,
  });

  /// Returns holidays from the scheduler API. When [year] is provided only
  /// holidays whose start date falls in that year are requested.
  Future<List<Holiday>> getHolidays({int? year});

  /// Creates a school holiday (`POST /api/v1/holidays`). Returns the created
  /// holiday alongside the API's success message.
  Future<(Holiday, String)> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description,
  });

  /// Updates a school holiday (`PATCH /api/v1/holidays/{code}`) using
  /// [version] as the optimistic-locking `If-Match` value.
  Future<(Holiday, String)> updateHoliday({
    required String code,
    required int version,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  });

  /// Approves/rejects a federal holiday
  /// (`PATCH /api/v1/holidays/{code}/status`).
  Future<(Holiday, String)> setHolidayStatus({
    required String code,
    required int version,
    required HolidayStatusAction action,
  });

  /// Deletes a school holiday, returning the API's success message.
  Future<String> deleteHoliday(String code);
}
