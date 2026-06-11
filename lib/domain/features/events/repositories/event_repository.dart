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

  /// Returns all holidays, seeding the mock dataset on the first call
  /// when the store is empty.
  Future<List<Holiday>> getHolidays();

  /// Creates or updates a holiday (matched by code).
  Future<Holiday> saveHoliday(Holiday holiday);

  Future<void> deleteHoliday(String code);
}
