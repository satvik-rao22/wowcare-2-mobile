import 'package:dio/dio.dart';

import '../../../../domain/features/events/entities/event.dart';
import '../models/event_models.dart';

/// STUB — the events backend is not yet available.
///
/// Reads return empty so the Events tab renders without crashing; writes throw
/// [UnimplementedError] until the API is wired. When the events endpoints ship
/// (expected on the scheduler microservice, alongside holidays), replace each
/// `TODO(events-api)` with the real call — mirror [HolidayRemoteDataSource]
/// (build the URL with `ApiPaths` + `ApiConstants.schedulerBaseUrl`, parse the
/// `{success, message, data, timestamp}` envelope).
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

  // Kept for when the events API is wired; unused by the stub.
  // ignore: unused_field
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
    // TODO(events-api): POST /api/v1/events.
    throw UnimplementedError(_notWired);
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
