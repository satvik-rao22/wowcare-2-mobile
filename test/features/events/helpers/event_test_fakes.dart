import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/events/datasources/event_remote_datasource.dart';
import 'package:wowcare/data/features/events/datasources/holiday_remote_datasource.dart';
import 'package:wowcare/data/features/events/models/holiday_models.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/repositories/event_repository.dart';

/// Programmable in-memory [EventRepository] for use-case and cubit tests.
///
/// Every holiday method records its arguments and returns the value staged on
/// the matching `next*` field; setting [error] makes every call throw it so
/// failure branches can be exercised. Event methods are stubbed just enough to
/// keep [EventsCubit.load] happy (empty events); the rest throw because the
/// holiday suite never touches them.
class FakeEventRepository implements EventRepository {
  // ---- staged results ----
  List<Event> nextEvents = const [];

  /// One entry per page index; requests beyond the list return empty/none.
  List<(List<Event>, bool)> pageResults = const [];
  final List<int> requestedPages = [];
  DateTime? lastPageFrom;
  List<Holiday> nextHolidays = const [];
  (Holiday, String)? nextCreate;
  (Holiday, String)? nextUpdate;
  (Holiday, String)? nextStatus;
  String nextDeleteMessage = 'Holiday deleted successfully';
  Object? error;

  // ---- recorded calls ----
  int getHolidaysCalls = 0;
  int? lastGetYear;
  Map<String, Object?>? lastCreateArgs;
  Map<String, Object?>? lastUpdateArgs;
  Map<String, Object?>? lastStatusArgs;
  String? lastDeletedCode;

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Holiday>> getHolidays({int? year}) async {
    _maybeThrow();
    getHolidaysCalls++;
    lastGetYear = year;
    return nextHolidays;
  }

  @override
  Future<(Holiday, String)> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    _maybeThrow();
    lastCreateArgs = {
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
    return nextCreate!;
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
    _maybeThrow();
    lastUpdateArgs = {
      'code': code,
      'version': version,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
    return nextUpdate!;
  }

  @override
  Future<(Holiday, String)> setHolidayStatus({
    required String code,
    required int version,
    required HolidayStatusAction action,
  }) async {
    _maybeThrow();
    lastStatusArgs = {'code': code, 'version': version, 'action': action};
    return nextStatus!;
  }

  @override
  Future<String> deleteHoliday(String code) async {
    _maybeThrow();
    lastDeletedCode = code;
    return nextDeleteMessage;
  }

  // ---- events ----
  @override
  Future<List<Event>> getEvents({
    required DateTime from,
    required DateTime to,
    String partyCode = '',
  }) async {
    _maybeThrow();
    return nextEvents;
  }

  @override
  Future<(List<Event>, bool)> getEventsPage({
    required DateTime from,
    required DateTime to,
    required int page,
    int size = 10,
    String partyCode = '',
  }) async {
    _maybeThrow();
    requestedPages.add(page);
    lastPageFrom = from;
    if (page >= pageResults.length) return (const <Event>[], false);
    return pageResults[page];
  }

  @override
  Future<List<CalendarFeedItem>> getCalendarFeed({
    required DateTime from,
    required DateTime to,
    required String scope,
    String partyCode = '',
  }) async => const [];

  @override
  Future<Event?> getEventByCode(String code) async => null;

  @override
  Future<Event> createEvent(Event event) => throw UnimplementedError();

  @override
  Future<Event> updateEvent(
    Event event, {
    String splitFromOccurrenceCode = '',
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEvent(String code, {String fromOccurrenceCode = ''}) =>
      throw UnimplementedError();

  @override
  Future<void> respondToOccurrence({
    required String eventCode,
    required String occurrenceCode,
    required String partyCode,
    required String partyType,
    required EventRsvpStatus status,
  }) => throw UnimplementedError();

  @override
  Future<void> updateOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String? overrideName,
    String? overrideDescription,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  }) => throw UnimplementedError();

  @override
  Future<void> cancelOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String reason = '',
  }) => throw UnimplementedError();
}

/// Records holiday calls and replays staged responses; used to test
/// [EventRepositoryImpl] in isolation from Dio.
class FakeHolidayRemoteDataSource implements HolidayRemoteDataSource {
  List<HolidayModel> nextHolidays = const [];
  (HolidayModel, String)? nextCreate;
  (HolidayModel, String)? nextUpdate;
  (HolidayModel, String)? nextStatus;
  String nextDeleteMessage = 'Holiday deleted successfully';

  int? lastGetYear;
  Map<String, Object?>? lastCreateArgs;
  Map<String, Object?>? lastUpdateArgs;
  Map<String, Object?>? lastStatusArgs;
  String? lastDeletedCode;

  @override
  Future<List<HolidayModel>> getHolidays({
    int? year,
    String? type,
    String? status,
  }) async {
    lastGetYear = year;
    return nextHolidays;
  }

  @override
  Future<(HolidayModel, String)> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    lastCreateArgs = {
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
    return nextCreate!;
  }

  @override
  Future<(HolidayModel, String)> updateHoliday({
    required String code,
    required int version,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    lastUpdateArgs = {
      'code': code,
      'version': version,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
    return nextUpdate!;
  }

  @override
  Future<(HolidayModel, String)> updateStatus({
    required String code,
    required int version,
    required HolidayStatusAction action,
  }) async {
    lastStatusArgs = {'code': code, 'version': version, 'action': action};
    return nextStatus!;
  }

  @override
  Future<String> deleteHoliday(String code) async {
    lastDeletedCode = code;
    return nextDeleteMessage;
  }
}

/// Event datasource stub — the holiday repository tests never invoke it.
class StubEventRemoteDataSource implements EventRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// In-memory [StorageService]; returns whatever is seeded in [values].
class FakeStorageService implements StorageService {
  FakeStorageService([Map<String, String>? seed])
    : values = {...?seed};

  final Map<String, String> values;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> saveString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}
