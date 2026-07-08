import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../domain/features/events/entities/event.dart';
import '../models/event_models.dart';

/// Talks to the Events API on the scheduler microservice (`/api/v1/events`).
/// Org/school scoping headers and the bearer token are attached globally by
/// [AuthInterceptor]; per-request headers set here are `Idempotency-Key` on
/// create and `If-Match` (optimistic locking) on writes.
///
/// Endpoints not yet wired keep their stub behaviour (reads return empty,
/// writes throw) and are being replaced step by step.
abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents();

  Future<EventModel?> getEventByCode(String code);

  Future<EventModel> createEvent(Event event);

  Future<EventModel> updateEvent(Event event);

  Future<void> deleteEvent(String code);

  Future<EventModel> respondToEvent({
    required String eventCode,
    required EventRsvp rsvp,
  });
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._client);

  final Dio _client;

  static const String _notWired =
      'Events API is not yet available. Wire EventRemoteDataSource to the '
      'scheduler microservice before using event create/update/delete/RSVP.';

  @override
  Future<List<EventModel>> getEvents() async {
    // TODO(events-api): GET /api/v1/events?year=&type=... on the scheduler MS.
    return const <EventModel>[];
  }

  @override
  Future<EventModel?> getEventByCode(String code) async {
    // TODO(events-api): GET /api/v1/events/{code}.
    return null;
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
      // One UUID per attempt: a network timeout retried by the caller
      // reuses a NEW key (new call), while the server dedupes an identical
      // replayed request (same key + body) instead of double-creating.
      options: Options(
        headers: <String, dynamic>{'Idempotency-Key': const Uuid().v4()},
      ),
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

  @override
  Future<EventModel> updateEvent(Event event) async {
    // TODO(events-api): PATCH /api/v1/events/{code}.
    throw UnimplementedError(_notWired);
  }

  @override
  Future<void> deleteEvent(String code) async {
    // TODO(events-api): DELETE /api/v1/events/{code}.
    throw UnimplementedError(_notWired);
  }

  @override
  Future<EventModel> respondToEvent({
    required String eventCode,
    required EventRsvp rsvp,
  }) async {
    // TODO(events-api): POST /api/v1/events/{code}/rsvp.
    throw UnimplementedError(_notWired);
  }
}
