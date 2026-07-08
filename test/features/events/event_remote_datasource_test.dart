import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/datasources/event_remote_datasource.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';

/// Fake [HttpClientAdapter] that captures the outgoing request and replays a
/// staged JSON response — same harness as the holiday datasource tests.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._responder);

  final ResponseBody Function(RequestOptions options) _responder;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

String? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value?.toString();
    }
  }
  return null;
}

Event _draft() => Event(
      code: '',
      type: EventType.classroom,
      name: 'Holiday activities',
      date: DateTime(2026, 7, 20),
      allDay: true,
      classrooms: const [EventAttendee(code: 'CLS_A', name: 'Bumblebees')],
      includeParents: true,
      createdAt: DateTime(2026, 7, 8),
      updatedAt: DateTime(2026, 7, 8),
    );

Map<String, dynamic> _createdPayload() => {
      'success': true,
      'message': 'Event created successfully',
      'data': {
        'code': 'EVT_NEW1',
        'type': 'CLASSROOM',
        'name': 'Holiday activities',
        'seriesStartDate': '2026-07-20',
        'allDayFlag': true,
        'includeParentsFlag': true,
        'recurringFlag': false,
        'version': 0,
        'audiences': [
          {'selectorKind': 'CLASSROOM', 'selectorCode': 'CLS_A'},
        ],
      },
    };

void main() {
  late Dio dio;
  late _FakeAdapter adapter;
  late EventRemoteDataSourceImpl dataSource;

  void stub(ResponseBody Function(RequestOptions) responder) {
    adapter = _FakeAdapter(responder);
    dio.httpClientAdapter = adapter;
  }

  setUp(() {
    dio = Dio()..transformer = SyncTransformer();
    dataSource = EventRemoteDataSourceImpl(dio);
  });

  group('createEvent', () {
    test('POSTs the contract body to /api/v1/events', () async {
      stub((_) => _jsonBody(_createdPayload(), status: 201));

      await dataSource.createEvent(_draft());

      final request = adapter.captured!;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/api/v1/events'));

      final body = request.data as Map<String, dynamic>;
      expect(body['type'], 'CLASSROOM');
      expect(body['audienceScope'], 'CLASSROOM_SET');
      expect(body['allDayFlag'], isTrue);
      expect(body['audiences'], [
        {'selectorKind': 'CLASSROOM', 'selectorCode': 'CLS_A'},
      ]);
    });

    test('sends a UUID Idempotency-Key per attempt', () async {
      stub((_) => _jsonBody(_createdPayload(), status: 201));

      await dataSource.createEvent(_draft());
      final first = _header(adapter.captured!, 'Idempotency-Key');

      await dataSource.createEvent(_draft());
      final second = _header(adapter.captured!, 'Idempotency-Key');

      expect(first, isNotNull);
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
      // A fresh key per call — retries are new attempts, not replays.
      expect(first, isNot(second));
    });

    test('returns the server-assigned event from the envelope', () async {
      stub((_) => _jsonBody(_createdPayload(), status: 201));

      final model = await dataSource.createEvent(_draft());

      expect(model.code, 'EVT_NEW1');
      expect(model.version, 0);
      expect(model.classrooms.single.code, 'CLS_A');
    });

    test('throws on an envelope without a data payload', () async {
      stub((_) => _jsonBody({'success': true, 'message': 'ok', 'data': null}));

      expect(
        () => dataSource.createEvent(_draft()),
        throwsA(isA<Exception>()),
      );
    });
  });
}
