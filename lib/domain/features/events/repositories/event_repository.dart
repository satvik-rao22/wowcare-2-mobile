import '../entities/event.dart';
import '../entities/holiday.dart';

abstract class EventRepository {
  /// Returns every locally stored event, seeding the mock dataset on the
  /// first call when the store is empty.
  Future<List<Event>> getEvents();

  Future<Event?> getEventByCode(String code);

  Future<Event> createEvent(Event event);

  Future<Event> updateEvent(Event event);

  Future<void> deleteEvent(String code);

  /// Upserts the current user's RSVP on [eventCode] and returns the
  /// updated event.
  Future<Event> respondToEvent({
    required String eventCode,
    required EventRsvp rsvp,
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
