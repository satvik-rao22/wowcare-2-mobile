import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/datasources/holiday_remote_datasource.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';

/// Fake [HttpClientAdapter] that captures the outgoing request and replays a
/// staged JSON response — lets us drive the real Dio request pipeline (query
/// params, headers, body serialization) without any network.
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

ResponseBody _jsonBody(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Case-insensitive header lookup (Dio does not normalize case on the way in).
String? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value?.toString();
    }
  }
  return null;
}

void main() {
  late Dio dio;
  late _FakeAdapter adapter;
  late HolidayRemoteDataSourceImpl dataSource;

  void stub(ResponseBody Function(RequestOptions) responder) {
    adapter = _FakeAdapter(responder);
    dio.httpClientAdapter = adapter;
  }

  setUp(() {
    dio = Dio()..transformer = SyncTransformer();
    dataSource = HolidayRemoteDataSourceImpl(dio);
  });

  group('getHolidays', () {
    test('flattens the grouped response and drops entries without a code', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'pendingFederal': [
              {
                'code': 'FED-1',
                'name': 'Columbus Day',
                'startDate': '2026-10-12',
                'type': 'FEDERAL',
                'status': 'PENDING',
              },
            ],
            'active': [
              {
                'code': 'SCH-1',
                'name': 'Spring Break',
                'startDate': '2026-03-16',
                'type': 'SCHOOL',
              },
              // No code — must be filtered out.
              {'name': 'Ghost', 'startDate': '2026-03-16', 'type': 'SCHOOL'},
            ],
            'rejectedFederal': [
              {
                'code': 'FED-2',
                'name': 'Flag Day',
                'startDate': '2026-06-14',
                'type': 'FEDERAL',
                'status': 'REJECTED',
              },
            ],
          },
        }),
      );

      final result = await dataSource.getHolidays(year: 2026);

      expect(result.map((h) => h.code).toList(), ['FED-1', 'SCH-1', 'FED-2']);
      expect(adapter.captured!.method, 'GET');
      expect(adapter.captured!.path, contains('/api/v1/holidays'));
      expect(adapter.captured!.queryParameters['year'], 2026);
    });

    test('omits the year query param when not provided', () async {
      stub((_) => _jsonBody({'data': <String, dynamic>{}}));
      await dataSource.getHolidays();
      expect(adapter.captured!.queryParameters.containsKey('year'), isFalse);
    });

    test('tolerates a flat list payload', () async {
      stub(
        (_) => _jsonBody({
          'data': [
            {'code': 'X1', 'name': 'One', 'startDate': '2026-01-01'},
          ],
        }),
      );
      final result = await dataSource.getHolidays();
      expect(result.single.code, 'X1');
    });

    test('returns empty for an unexpected payload shape', () async {
      stub((_) => _jsonBody({'unexpected': true}));
      expect(await dataSource.getHolidays(), isEmpty);
    });
  });

  group('createHoliday', () {
    test('POSTs the create body and returns the server message', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'code': 'SCH-9',
            'name': 'Founders Day',
            'startDate': '2026-05-01',
            'endDate': '2026-05-01',
            'type': 'SCHOOL',
          },
          'message': 'School holiday created successfully',
        }),
      );

      final (holiday, message) = await dataSource.createHoliday(
        name: 'Founders Day',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 1),
        description: 'desc',
      );

      expect(holiday.code, 'SCH-9');
      expect(message, 'School holiday created successfully');
      expect(adapter.captured!.method, 'POST');
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['name'], 'Founders Day');
      expect(body['startDate'], '2026-05-01'); // formatted YYYY-MM-DD
      expect(body['description'], 'desc');
    });

    test('uses a fallback message when the server omits one', () async {
      stub(
        (_) => _jsonBody({
          'data': {'code': 'SCH-9', 'name': 'x', 'startDate': '2026-05-01'},
        }),
      );
      final (_, message) = await dataSource.createHoliday(
        name: 'x',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 1),
      );
      expect(message, 'Holiday created successfully');
    });

    test('throws when the response has no data payload', () async {
      stub((_) => _jsonBody({'message': 'ok'}));
      expect(
        () => dataSource.createHoliday(
          name: 'x',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('updateHoliday', () {
    test('sends only provided fields, dates together', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'code': 'SCH-1',
            'name': 'Renamed',
            'startDate': '2026-03-16',
            'endDate': '2026-03-20',
            'type': 'SCHOOL',
          },
          'message': 'updated',
        }),
      );

      await dataSource.updateHoliday(
        code: 'SCH-1',
        version: 4,
        name: 'Renamed',
        startDate: DateTime(2026, 3, 16),
        endDate: DateTime(2026, 3, 20),
      );

      expect(adapter.captured!.method, 'PATCH');
      expect(adapter.captured!.path, contains('/api/v1/holidays/SCH-1'));
      // V14 removed If-Match optimistic locking.
      expect(_header(adapter.captured!, 'If-Match'), isNull);
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['name'], 'Renamed');
      expect(body['startDate'], '2026-03-16');
      expect(body['endDate'], '2026-03-20');
      // description not provided → not sent.
      expect(body.containsKey('description'), isFalse);
    });

    test('omits dates when only one bound is provided', () async {
      stub(
        (_) => _jsonBody({
          'data': {'code': 'SCH-1', 'name': 'x', 'startDate': '2026-03-16'},
          'message': 'ok',
        }),
      );
      await dataSource.updateHoliday(
        code: 'SCH-1',
        version: 1,
        startDate: DateTime(2026, 3, 16),
      );
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body.containsKey('startDate'), isFalse);
      expect(body.containsKey('endDate'), isFalse);
    });
  });

  group('updateStatus', () {
    test('sends the action', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'code': 'FED-1',
            'name': 'Columbus Day',
            'startDate': '2026-10-12',
            'type': 'FEDERAL',
            'status': 'CONSIDERED',
          },
          'message': 'approved',
        }),
      );

      final (holiday, message) = await dataSource.updateStatus(
        code: 'FED-1',
        version: 2,
        action: HolidayStatusAction.approve,
      );

      // Datasource returns the raw DTO; status is still the wire string.
      expect(holiday.status, 'CONSIDERED');
      expect(message, 'approved');
      expect(adapter.captured!.method, 'PATCH');
      expect(adapter.captured!.path, contains('/api/v1/holidays/FED-1/status'));
      expect(_header(adapter.captured!, 'If-Match'), isNull);
      expect(
        (adapter.captured!.data as Map<String, dynamic>)['action'],
        'APPROVE',
      );
    });
  });

  group('deleteHoliday', () {
    test('returns the server message', () async {
      stub((_) => _jsonBody({'message': 'Holiday removed'}));
      final message = await dataSource.deleteHoliday('SCH-1');
      expect(message, 'Holiday removed');
      expect(adapter.captured!.method, 'DELETE');
      expect(adapter.captured!.path, contains('/api/v1/holidays/SCH-1'));
    });

    test('falls back when no message is returned', () async {
      stub((_) => _jsonBody({'data': null}));
      expect(
        await dataSource.deleteHoliday('SCH-1'),
        'Holiday deleted successfully',
      );
    });
  });
}
