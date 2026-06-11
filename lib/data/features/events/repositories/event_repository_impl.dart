import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/events/datasources/event_local_datasource.dart';
import 'package:wowcare/data/features/events/datasources/event_seed_datasource.dart';
import 'package:wowcare/data/features/events/models/event_collection.dart';
import 'package:wowcare/data/features/events/models/holiday_collection.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(
    this._localDataSource,
    this._seedDataSource,
    this._storageService,
  );

  final EventLocalDataSource _localDataSource;
  final EventSeedDataSource _seedDataSource;
  final StorageService _storageService;

  /// One-shot flags so user deletions aren't resurrected by reseeding.
  static const String _seededFlagKey = 'events_mock_seeded_v1';
  static const String _holidaysSeededFlagKey = 'holidays_mock_seeded_v1';

  @override
  Future<List<Event>> getEvents() async {
    await _seedIfNeeded();
    final rows = await _localDataSource.getAll();
    final events = rows.map((r) => r.toEntity()).toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.startTime.compareTo(b.startTime);
      });
    return events;
  }

  @override
  Future<Event?> getEventByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final rows = await _localDataSource.getAll();
    for (final row in rows) {
      if (row.code == trimmed) return row.toEntity();
    }
    return null;
  }

  @override
  Future<Event> createEvent(Event event) async {
    await _localDataSource.upsert(EventCollection.fromEntity(event));
    return event;
  }

  @override
  Future<Event> updateEvent(Event event) async {
    final updated = event.copyWith(updatedAt: DateTime.now());
    await _localDataSource.upsert(EventCollection.fromEntity(updated));
    return updated;
  }

  @override
  Future<void> deleteEvent(String code) {
    return _localDataSource.deleteByCode(code.trim());
  }

  @override
  Future<Event> respondToEvent({
    required String eventCode,
    required EventRsvp rsvp,
  }) async {
    final event = await getEventByCode(eventCode);
    if (event == null) {
      throw StateError('Event $eventCode not found');
    }
    final others =
        event.rsvps.where((r) => r.userCode != rsvp.userCode).toList();
    final updated = event.copyWith(
      rsvps: [...others, rsvp],
      updatedAt: DateTime.now(),
    );
    await _localDataSource.upsert(EventCollection.fromEntity(updated));
    return updated;
  }

  @override
  Future<List<Holiday>> getHolidays() async {
    await _seedHolidaysIfNeeded();
    final rows = await _localDataSource.getAllHolidays();
    return rows.map((r) => r.toEntity()).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  @override
  Future<Holiday> saveHoliday(Holiday holiday) async {
    final updated = holiday.copyWith(updatedAt: DateTime.now());
    await _localDataSource.upsertHoliday(
      HolidayCollection.fromEntity(updated),
    );
    return updated;
  }

  @override
  Future<void> deleteHoliday(String code) {
    return _localDataSource.deleteHolidayByCode(code.trim());
  }

  Future<void> _seedHolidaysIfNeeded() async {
    final alreadySeeded =
        await _storageService.getBool(_holidaysSeededFlagKey) ?? false;
    if (alreadySeeded) return;
    final existing = await _localDataSource.getAllHolidays();
    if (existing.isEmpty) {
      final seeds = await _seedDataSource.fetchHolidays();
      if (seeds.isNotEmpty) {
        await _localDataSource.upsertAllHolidays(
          seeds
              .map((m) => HolidayCollection.fromEntity(m.toEntity()))
              .toList(),
        );
      }
    }
    await _storageService.saveBool(_holidaysSeededFlagKey, true);
  }

  Future<void> _seedIfNeeded() async {
    final alreadySeeded =
        await _storageService.getBool(_seededFlagKey) ?? false;
    if (alreadySeeded) return;
    final existing = await _localDataSource.getAll();
    if (existing.isEmpty) {
      final seeds = await _seedDataSource.fetchEvents();
      if (seeds.isNotEmpty) {
        await _localDataSource.upsertAll(
          seeds
              .map((m) => EventCollection.fromEntity(m.toEntity()))
              .toList(),
        );
      }
    }
    await _storageService.saveBool(_seededFlagKey, true);
  }
}
