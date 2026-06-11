import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/data/features/events/models/event_collection.dart';
import 'package:wowcare/data/features/events/models/holiday_collection.dart';

/// Isar-backed persistence for events and holidays. All reads/writes go
/// through the shared [CacheService] so they live in the same database
/// (and follow the same wipe-on-logout rules) as the rest of the app's
/// local data.
abstract class EventLocalDataSource {
  Future<List<EventCollection>> getAll();

  Future<void> upsert(EventCollection event);

  Future<void> upsertAll(List<EventCollection> events);

  Future<void> deleteByCode(String code);

  Future<void> clear();

  Future<List<HolidayCollection>> getAllHolidays();

  Future<void> upsertHoliday(HolidayCollection holiday);

  Future<void> upsertAllHolidays(List<HolidayCollection> holidays);

  Future<void> deleteHolidayByCode(String code);
}

class EventLocalDataSourceImpl implements EventLocalDataSource {
  EventLocalDataSourceImpl(this._cacheService);

  final CacheService _cacheService;

  @override
  Future<List<EventCollection>> getAll() {
    return _cacheService.getAll<EventCollection>();
  }

  @override
  Future<void> upsert(EventCollection event) {
    return _cacheService.put<EventCollection>(event);
  }

  @override
  Future<void> upsertAll(List<EventCollection> events) {
    return _cacheService.putAll<EventCollection>(events);
  }

  @override
  Future<void> deleteByCode(String code) {
    return _cacheService.delete<EventCollection>(fastHash(code));
  }

  @override
  Future<void> clear() {
    return _cacheService.clear<EventCollection>();
  }

  @override
  Future<List<HolidayCollection>> getAllHolidays() {
    return _cacheService.getAll<HolidayCollection>();
  }

  @override
  Future<void> upsertHoliday(HolidayCollection holiday) {
    return _cacheService.put<HolidayCollection>(holiday);
  }

  @override
  Future<void> upsertAllHolidays(List<HolidayCollection> holidays) {
    return _cacheService.putAll<HolidayCollection>(holidays);
  }

  @override
  Future<void> deleteHolidayByCode(String code) {
    return _cacheService.delete<HolidayCollection>(fastHash(code));
  }
}
