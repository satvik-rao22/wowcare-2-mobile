import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../domain/features/events/entities/event.dart';
import '../models/event_models.dart';

/// Talks to the Events API on the Events/Todo microservice
/// (`/api/v1/events`). Org/school scoping headers and the bearer token are
/// attached globally by [AuthInterceptor]. V14 of the API removed
/// If-Match / ETag / Idempotency-Key — they must NOT be sent.
abstract class EventRemoteDataSource {
  /// `GET /api/v1/occurrences?fromDate=&toDate=` — the rich occurrence
  /// view (display fields + myRsvp + rsvpSummary + participants), one row
  /// per occurrence, paged through until the window is fully loaded.
  /// [partyCode] goes out as `X-Party-Code` so rows carry `myRsvp`.
  Future<List<EventModel>> getOccurrencesWindow({
    required DateTime from,
    required DateTime to,
    String partyCode,
  });

  /// One page of the occurrence view — infinite-scroll for grid/list.
  /// Returns the rows and whether more pages exist.
  Future<(List<EventModel>, bool)> getOccurrencesPage({
    required DateTime from,
    required DateTime to,
    required int page,
    int size,
    String partyCode,
  });

  Future<EventModel?> getEventByCode(String code);

  Future<EventModel> createEvent(Event event);

  /// `PATCH /api/v1/events/{code}`. With [splitFromOccurrenceCode] the
  /// scope becomes THIS_AND_FUTURE: the series is split at that occurrence
  /// and the response carries the NEW event's code.
  Future<EventModel> updateEvent(
    Event event, {
    String splitFromOccurrenceCode,
  });

  /// `DELETE /api/v1/events/{code}`. With [fromOccurrenceCode] the scope
  /// becomes THIS_AND_FUTURE: occurrences from that one onward are
  /// cancelled and the series' end is capped; earlier ones stay.
  Future<void> deleteEvent(String code, {String fromOccurrenceCode});

  /// `PATCH /api/v1/events/{code}/occurrences/{occ}?scope=THIS_ONLY` —
  /// override name/description/date/times of one occurrence.
  Future<void> updateOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String? overrideName,
    String? overrideDescription,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  });

  /// `DELETE /api/v1/events/{code}/occurrences/{occ}?reason=` — cancel a
  /// single occurrence.
  Future<void> cancelOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String reason,
  });

  /// `POST /api/v1/events/{code}/occurrences/{occ}/rsvp` — upsert
  /// (201 first time, 200 on change).
  Future<void> respondToOccurrence({
    required String eventCode,
    required String occurrenceCode,
    required String partyCode,
    required String partyType,
    required EventRsvpStatus status,
  });
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<List<EventModel>> getOccurrencesWindow({
    required DateTime from,
    required DateTime to,
    String partyCode = '',
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.occurrencesView,
      ApiConstants.schedulerBaseUrl,
    );

    final items = <EventModel>[];
    var page = 0;
    while (true) {
      final response = await _client.get<dynamic>(
        endpoint,
        queryParameters: <String, dynamic>{
          'fromDate': EventModel.formatDate(from),
          'toDate': EventModel.formatDate(to),
          'page': page,
          'size': 100,
          'sort': 'date_asc',
        },
        options: partyCode.trim().isEmpty
            ? null
            : Options(
                headers: <String, dynamic>{'X-Party-Code': partyCode.trim()},
              ),
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) break;
      final data = raw['data'];
      if (data is! Map<String, dynamic>) break;

      final rows = data['items'];
      if (rows is List) {
        for (final entry in rows.whereType<Map>()) {
          final model = EventModel.fromOccurrenceApi(
            entry.map((k, v) => MapEntry(k.toString(), v)),
          );
          if (model.code.isNotEmpty) items.add(model);
        }
      }

      final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      page++;
      if (page >= totalPages) break;
    }
    return items;
  }

  @override
  Future<(List<EventModel>, bool)> getOccurrencesPage({
    required DateTime from,
    required DateTime to,
    required int page,
    int size = 10,
    String partyCode = '',
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.occurrencesView,
      ApiConstants.schedulerBaseUrl,
    );
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'fromDate': EventModel.formatDate(from),
        'toDate': EventModel.formatDate(to),
        'page': page,
        'size': size,
        'sort': 'date_asc',
      },
      options: partyCode.trim().isEmpty
          ? null
          : Options(
              headers: <String, dynamic>{'X-Party-Code': partyCode.trim()},
            ),
    );
    final raw = response.data;
    final data = raw is Map<String, dynamic> ? raw['data'] : null;
    if (data is! Map<String, dynamic>) return (const <EventModel>[], false);
    final rows = data['items'];
    final items = <EventModel>[];
    if (rows is List) {
      for (final entry in rows.whereType<Map>()) {
        final model = EventModel.fromOccurrenceApi(
          entry.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (model.code.isNotEmpty) items.add(model);
      }
    }
    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    return (items, page + 1 < totalPages);
  }

  @override
  Future<EventModel?> getEventByCode(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.eventByCode(code),
      ApiConstants.schedulerBaseUrl,
    );
    try {
      final response = await _client.get<dynamic>(endpoint);
      return _parseSingle(response.data, action: 'get');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<EventModel> createEvent(Event event) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.events,
      ApiConstants.schedulerBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: EventModel.createBody(event),
    );

    return _parseSingle(response.data, action: 'create');
  }

  /// Unwraps the `{success, message, data}` envelope around one event.
  static EventModel _parseSingle(dynamic raw, {required String action}) {
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected event $action API response format');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload in event $action response');
    }
    return EventModel.fromApi(data);
  }

  /// `PATCH /api/v1/events/{code}?scope=ALL`. Sends only the fields the
  /// backend supports editing (see [EventModel.updateBody]) —
  /// type/audience/recurrence-structure changes are deferred to a later
  /// backend sprint and locked in the edit UI. Occurrence-level scopes
  /// (THIS_AND_FUTURE) come with occurrence support.
  @override
  Future<EventModel> updateEvent(
    Event event, {
    String splitFromOccurrenceCode = '',
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.eventByCode(event.code),
      ApiConstants.schedulerBaseUrl,
    );

    final splitFrom = splitFromOccurrenceCode.trim();
    final response = await _client.patch<dynamic>(
      endpoint,
      data: EventModel.updateBody(event),
      queryParameters: splitFrom.isEmpty
          ? const <String, dynamic>{'scope': 'ALL'}
          : <String, dynamic>{
              'scope': 'THIS_AND_FUTURE',
              'occurrence': splitFrom,
            },
    );

    return _parseSingle(response.data, action: 'update');
  }

  /// `DELETE /api/v1/events/{code}?scope=ALL` — soft-deletes the event and
  /// cascades to occurrences, participants, audiences and attachments.
  @override
  Future<void> deleteEvent(String code, {String fromOccurrenceCode = ''}) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.eventByCode(code),
      ApiConstants.schedulerBaseUrl,
    );
    final fromOccurrence = fromOccurrenceCode.trim();
    await _client.delete<dynamic>(
      endpoint,
      queryParameters: fromOccurrence.isEmpty
          ? const <String, dynamic>{'scope': 'ALL'}
          : <String, dynamic>{
              'scope': 'THIS_AND_FUTURE',
              'occurrence': fromOccurrence,
            },
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
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.eventOccurrences(eventCode)}/'
      '${Uri.encodeComponent(occurrenceCode.trim())}',
      ApiConstants.schedulerBaseUrl,
    );

    await _client.patch<dynamic>(
      endpoint,
      queryParameters: const <String, dynamic>{'scope': 'THIS_ONLY'},
      // PATCH semantics: omitted fields stay untouched.
      data: <String, dynamic>{
        if (overrideName != null && overrideName.trim().isNotEmpty)
          'overrideName': overrideName.trim(),
        if (overrideDescription != null &&
            overrideDescription.trim().isNotEmpty)
          'overrideDescription': overrideDescription.trim(),
        if (scheduledStartDate != null)
          'scheduledStartDate': EventModel.formatDate(scheduledStartDate),
        if (scheduledStartTime != null && scheduledStartTime.isNotEmpty)
          'scheduledStartTime': EventModel.apiTime(scheduledStartTime),
        if (scheduledEndTime != null && scheduledEndTime.isNotEmpty)
          'scheduledEndTime': EventModel.apiTime(scheduledEndTime),
      },
    );
  }

  @override
  Future<void> cancelOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String reason = '',
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.eventOccurrences(eventCode)}/'
      '${Uri.encodeComponent(occurrenceCode.trim())}',
      ApiConstants.schedulerBaseUrl,
    );

    await _client.delete<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  @override
  Future<void> respondToOccurrence({
    required String eventCode,
    required String occurrenceCode,
    required String partyCode,
    required String partyType,
    required EventRsvpStatus status,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.occurrenceRsvp(eventCode, occurrenceCode),
      ApiConstants.schedulerBaseUrl,
    );

    await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'partyCode': partyCode,
        'partyType': partyType,
        'status': status.value,
      },
    );
  }

}
