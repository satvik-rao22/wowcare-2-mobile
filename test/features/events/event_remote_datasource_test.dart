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

    test('sends no Idempotency-Key (removed in API V14)', () async {
      stub((_) => _jsonBody(_createdPayload(), status: 201));

      await dataSource.createEvent(_draft());

      expect(_header(adapter.captured!, 'Idempotency-Key'), isNull);
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

  group('getOccurrencesWindow', () {
    Map<String, dynamic> page(int page, int totalPages, List<String> codes) =>
        {
          'success': true,
          'data': {
            'items': [
              for (final code in codes)
                {
                  'occurrenceCode': 'OCC_$code',
                  'eventCode': code,
                  'type': 'SCHOOL',
                  'displayName': 'Event $code',
                  'scheduledStartDate': '2026-09-15',
                  'allDayFlag': true,
                  'recurring': false,
                  'includeParentsFlag': true,
                  'myRsvp': {'status': 'ATTENDING', 'implicit': false},
                  'participants': {
                    'staff': [
                      {
                        'partyCode': 'STF_1',
                        'entityCode': 'STF_1',
                        'name': 'Ms. Rivera',
                        'rsvp': 'ATTENDING',
                        'respondedAt': '2026-07-15T09:00:00Z',
                      },
                    ],
                    'parents': [
                      {
                        'partyCode': 'GRD_1',
                        'entityCode': 'GRD_1',
                        'name': 'Anna Smith',
                        'rsvp': null,
                        'linkedStudentCode': 'STD_1',
                      },
                    ],
                  },
                },
            ],
            'totalElements': codes.length * totalPages,
            'totalPages': totalPages,
            'page': page,
            'size': 100,
          },
        };

    test('walks pages, sends the window and X-Party-Code, parses rows',
        () async {
      final requestedPages = <String>[];
      stub((options) {
        requestedPages.add(options.uri.queryParameters['page'] ?? '0');
        return _jsonBody(
          (options.uri.queryParameters['page'] ?? '0') == '0'
              ? page(0, 2, ['EVT_1', 'EVT_2'])
              : page(1, 2, ['EVT_3']),
        );
      });

      final rows = await dataSource.getOccurrencesWindow(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        partyCode: 'STF_1',
      );

      final request = adapter.captured!;
      expect(request.uri.path, endsWith('/api/v1/occurrences'));
      expect(request.uri.queryParameters['fromDate'], '2026-09-01');
      expect(request.uri.queryParameters['toDate'], '2026-09-30');
      expect(_header(request, 'X-Party-Code'), 'STF_1');
      expect(requestedPages, ['0', '1']);

      expect(rows.map((r) => r.code), ['EVT_1', 'EVT_2', 'EVT_3']);
      final first = rows.first;
      expect(first.occurrenceCode, 'OCC_EVT_1');
      expect(first.name, 'Event EVT_1');
      expect(first.myRsvpStatus, 'ATTENDING');
      // Roster: staff with names + parents; only responded rows become
      // RSVP entries.
      expect(first.staff.single.name, 'Ms. Rivera');
      expect(first.parents.single.code, 'GRD_1');
      expect(first.rsvps.single.userCode, 'STF_1');
    });

    test('returns empty on a malformed payload instead of throwing', () async {
      stub((_) => _jsonBody({'success': true, 'data': null}));
      expect(
        await dataSource.getOccurrencesWindow(
          from: DateTime(2026, 9, 1),
          to: DateTime(2026, 9, 30),
        ),
        isEmpty,
      );
    });
  });

  group('getEventByCode', () {
    test('GETs the event and parses the envelope', () async {
      stub((_) => _jsonBody(_createdPayload()));

      final model = await dataSource.getEventByCode('EVT_NEW1');

      expect(adapter.captured!.method, 'GET');
      expect(adapter.captured!.uri.path, endsWith('/api/v1/events/EVT_NEW1'));
      expect(model!.code, 'EVT_NEW1');
    });

    test('resolves null on 404', () async {
      stub(
        (_) => _jsonBody(
          {'success': false, 'code': 'NOT_FOUND', 'data': null},
          status: 404,
        ),
      );

      expect(await dataSource.getEventByCode('EVT_GONE'), isNull);
    });
  });

  group('updateEvent', () {
    test('PATCHes with scope=ALL and only the editable fields', () async {
      stub((_) => _jsonBody(_createdPayload()));

      await dataSource.updateEvent(
        _draft().copyWith(code: 'EVT_NEW1', version: 3, name: 'Renamed'),
      );

      final request = adapter.captured!;
      expect(request.method, 'PATCH');
      expect(request.uri.path, endsWith('/api/v1/events/EVT_NEW1'));
      expect(request.uri.queryParameters['scope'], 'ALL');
      // V14 removed If-Match optimistic locking.
      expect(_header(request, 'If-Match'), isNull);

      final body = request.data as Map<String, dynamic>;
      expect(body['name'], 'Renamed');
      expect(body['allDayFlag'], isTrue);
      // Everything is editable except the event type (and its derived
      // audience scope).
      expect(body['audiences'], isNotEmpty);
      expect(body['includeParentsFlag'], isTrue);
      expect(body.containsKey('description'), isTrue);
      expect(body.containsKey('type'), isFalse);
      expect(body.containsKey('audienceScope'), isFalse);
    });

    test('sends the full rrule for recurring events', () async {
      stub((_) => _jsonBody(_createdPayload()));

      await dataSource.updateEvent(
        _draft().copyWith(
          code: 'EVT_NEW1',
          recurring: true,
          recurrence: () => RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 2,
            daysOfWeek: {DateTime.monday},
            endDate: DateTime(2026, 12, 18),
          ),
        ),
      );

      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['recurringFlag'], isTrue);
      expect(body['rrule'], 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO;UNTIL=20261218');
    });
  });

  group('deleteEvent', () {
    test('DELETEs with scope=ALL', () async {
      stub((_) => ResponseBody.fromString('', 204));

      await dataSource.deleteEvent('EVT_NEW1');

      final request = adapter.captured!;
      expect(request.method, 'DELETE');
      expect(request.uri.path, endsWith('/api/v1/events/EVT_NEW1'));
      expect(request.uri.queryParameters['scope'], 'ALL');
    });
  });

  group('THIS_AND_FUTURE scopes', () {
    test('update with splitFromOccurrenceCode splits the series', () async {
      stub((_) => _jsonBody(_createdPayload()));

      await dataSource.updateEvent(
        _draft().copyWith(code: 'EVT_1', name: 'From here on'),
        splitFromOccurrenceCode: 'OCC_5',
      );

      final request = adapter.captured!;
      expect(request.method, 'PATCH');
      expect(request.uri.queryParameters['scope'], 'THIS_AND_FUTURE');
      expect(request.uri.queryParameters['occurrence'], 'OCC_5');
    });

    test('delete with fromOccurrenceCode cancels from that occurrence',
        () async {
      stub((_) => ResponseBody.fromString('', 204));

      await dataSource.deleteEvent('EVT_1', fromOccurrenceCode: 'OCC_5');

      final request = adapter.captured!;
      expect(request.method, 'DELETE');
      expect(request.uri.queryParameters['scope'], 'THIS_AND_FUTURE');
      expect(request.uri.queryParameters['occurrence'], 'OCC_5');
    });
  });

  group('updateOccurrence', () {
    test('PATCHes THIS_ONLY with only the provided overrides', () async {
      stub((_) => _jsonBody({'success': true, 'data': {}}));

      await dataSource.updateOccurrence(
        eventCode: 'EVT_1',
        occurrenceCode: 'OCC_1',
        overrideName: 'Rescheduled',
        scheduledStartTime: '10:30',
        scheduledEndTime: '11:30',
      );

      final request = adapter.captured!;
      expect(request.method, 'PATCH');
      expect(
        request.uri.path,
        endsWith('/api/v1/events/EVT_1/occurrences/OCC_1'),
      );
      expect(request.uri.queryParameters['scope'], 'THIS_ONLY');
      expect(request.data, {
        'overrideName': 'Rescheduled',
        'scheduledStartTime': '10:30:00',
        'scheduledEndTime': '11:30:00',
      });
    });
  });

  group('cancelOccurrence', () {
    test('DELETEs with the optional reason', () async {
      stub((_) => _jsonBody({'success': true, 'data': {}}));

      await dataSource.cancelOccurrence(
        eventCode: 'EVT_1',
        occurrenceCode: 'OCC_1',
        reason: 'Teacher sick',
      );

      final request = adapter.captured!;
      expect(request.method, 'DELETE');
      expect(
        request.uri.path,
        endsWith('/api/v1/events/EVT_1/occurrences/OCC_1'),
      );
      expect(request.uri.queryParameters['reason'], 'Teacher sick');
    });
  });

  group('respondToOccurrence', () {
    test('POSTs the RSVP body to the occurrence rsvp endpoint', () async {
      stub(
        (_) => _jsonBody({
          'success': true,
          'data': {'created': true},
        }, status: 201),
      );

      await dataSource.respondToOccurrence(
        eventCode: 'EVT_NEW1',
        occurrenceCode: 'OCC_1',
        partyCode: 'GUA_9',
        partyType: 'PARENT',
        status: EventRsvpStatus.attending,
      );

      final request = adapter.captured!;
      expect(request.method, 'POST');
      expect(
        request.uri.path,
        endsWith('/api/v1/events/EVT_NEW1/occurrences/OCC_1/rsvp'),
      );
      expect(request.data, {
        'partyCode': 'GUA_9',
        'partyType': 'PARENT',
        'status': 'ATTENDING',
      });
    });
  });
}
