import 'package:wowcare/data/features/events/datasources/event_remote_datasource.dart';
import 'package:wowcare/data/features/events/datasources/holiday_remote_datasource.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/repositories/event_repository.dart';

/// Remote-only implementation. Holidays are live from the scheduler API;
/// events are served by [EventRemoteDataSource] (currently a stub until the
/// events backend is available). No Isar persistence or mock seeding.
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(
    this._eventRemoteDataSource,
    this._holidayRemoteDataSource,
  );

  final EventRemoteDataSource _eventRemoteDataSource;
  final HolidayRemoteDataSource _holidayRemoteDataSource;

  // --------------------------------------------------------------- events

  @override
  Future<List<Event>> getEvents({
    required DateTime from,
    required DateTime to,
    String partyCode = '',
  }) async {
    final models = await _eventRemoteDataSource.getOccurrencesWindow(
      from: from,
      to: to,
      partyCode: partyCode,
    );
    return models.map((m) => m.toEntity()).toList()..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.startTime.compareTo(b.startTime);
    });
  }

  @override
  Future<(List<Event>, bool)> getEventsPage({
    required DateTime from,
    required DateTime to,
    required int page,
    int size = 10,
    String partyCode = '',
  }) async {
    final (models, hasMore) = await _eventRemoteDataSource.getOccurrencesPage(
      from: from,
      to: to,
      page: page,
      size: size,
      partyCode: partyCode,
    );
    return (models.map((m) => m.toEntity()).toList(), hasMore);
  }

  @override
  Future<Event?> getEventByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final model = await _eventRemoteDataSource.getEventByCode(trimmed);
    return model?.toEntity();
  }

  @override
  Future<Event> createEvent(Event event) async {
    final model = await _eventRemoteDataSource.createEvent(event);
    return model.toEntity();
  }

  @override
  Future<Event> updateEvent(
    Event event, {
    String splitFromOccurrenceCode = '',
  }) async {
    final model = await _eventRemoteDataSource.updateEvent(
      event,
      splitFromOccurrenceCode: splitFromOccurrenceCode,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteEvent(String code, {String fromOccurrenceCode = ''}) {
    return _eventRemoteDataSource.deleteEvent(
      code.trim(),
      fromOccurrenceCode: fromOccurrenceCode,
    );
  }

  @override
  Future<void> respondToOccurrence({
    required String eventCode,
    required String occurrenceCode,
    required String partyCode,
    required String partyType,
    required EventRsvpStatus status,
  }) {
    return _eventRemoteDataSource.respondToOccurrence(
      eventCode: eventCode,
      occurrenceCode: occurrenceCode,
      partyCode: partyCode,
      partyType: partyType,
      status: status,
    );
  }

  @override
  Future<void> updateOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String? overrideName,
    String? overrideDescription,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  }) {
    return _eventRemoteDataSource.updateOccurrence(
      eventCode: eventCode,
      occurrenceCode: occurrenceCode,
      overrideName: overrideName,
      overrideDescription: overrideDescription,
      scheduledStartDate: scheduledStartDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
    );
  }

  @override
  Future<void> cancelOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String reason = '',
  }) {
    return _eventRemoteDataSource.cancelOccurrence(
      eventCode: eventCode,
      occurrenceCode: occurrenceCode,
      reason: reason,
    );
  }

  // ------------------------------------------------------------- holidays

  @override
  Future<List<Holiday>> getHolidays({int? year}) async {
    final models = await _holidayRemoteDataSource.getHolidays(year: year);
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  @override
  Future<(Holiday, String)> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    final (model, message) = await _holidayRemoteDataSource.createHoliday(
      name: name,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );
    return (model.toEntity(), message);
  }

  @override
  Future<(Holiday, String)> updateHoliday({
    required String code,
    required int version,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    final (model, message) = await _holidayRemoteDataSource.updateHoliday(
      code: code,
      version: version,
      name: name,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );
    return (model.toEntity(), message);
  }

  @override
  Future<(Holiday, String)> setHolidayStatus({
    required String code,
    required int version,
    required HolidayStatusAction action,
  }) async {
    final (model, message) = await _holidayRemoteDataSource.updateStatus(
      code: code,
      version: version,
      action: action,
    );
    return (model.toEntity(), message);
  }

  @override
  Future<String> deleteHoliday(String code) {
    return _holidayRemoteDataSource.deleteHoliday(code.trim());
  }
}
