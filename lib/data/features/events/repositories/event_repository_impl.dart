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
  Future<List<Event>> getEvents() async {
    final models = await _eventRemoteDataSource.getEvents();
    return models.map((m) => m.toEntity()).toList()..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.startTime.compareTo(b.startTime);
    });
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
  Future<Event> updateEvent(Event event) async {
    final model = await _eventRemoteDataSource.updateEvent(event);
    return model.toEntity();
  }

  @override
  Future<void> deleteEvent(String code) {
    return _eventRemoteDataSource.deleteEvent(code.trim());
  }

  @override
  Future<Event> respondToEvent({
    required String eventCode,
    required EventRsvp rsvp,
  }) async {
    final model = await _eventRemoteDataSource.respondToEvent(
      eventCode: eventCode,
      rsvp: rsvp,
    );
    return model.toEntity();
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
