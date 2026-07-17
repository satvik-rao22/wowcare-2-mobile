import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/tasks/datasources/task_remote_datasource.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';

/// Fake [HttpClientAdapter] that captures the outgoing request and replays a
/// staged JSON response — drives the real Dio pipeline without any network.
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

/// Storage stub that only serves the logged-in staff code.
class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.staffCode ? 'STF_ME' : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Case-insensitive header lookup (Dio does not normalize case on the way in).
String? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value?.toString();
    }
  }
  return null;
}

ResponseBody _jsonBody(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Task _draft() => Task(
      code: '',
      title: 'Prepare report',
      description: 'Q3 summary',
      priority: TaskPriority.high,
      effort: 3,
      startDate: DateTime(2026, 7, 15),
      dueDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late Dio dio;
  late _FakeAdapter adapter;
  late TaskRemoteDataSourceImpl dataSource;

  void stub(ResponseBody Function(RequestOptions) responder) {
    adapter = _FakeAdapter(responder);
    dio.httpClientAdapter = adapter;
  }

  setUp(() {
    dio = Dio()..transformer = SyncTransformer();
    dataSource = TaskRemoteDataSourceImpl(dio, _FakeStorage());
  });

  group('getAssignments', () {
    test('GETs the flat endpoint with page/size and unwraps data.items', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'items': [
              {
                'code': 'TSA_1',
                'taskCode': 'TSK_1',
                'title': 'A',
                'assigneeCode': 'STF_1',
                'occurrenceDate': '2026-07-15',
                'dueAt': '2026-07-17T17:00:00Z',
                'priority': 'HIGH',
                'status': 'TO_DO',
              },
              // No code — filtered out.
              {'taskCode': 'TSK_2', 'title': 'ghost', 'occurrenceDate': '2026-07-15'},
            ],
            'page': 0,
            'size': 500,
          },
        }),
      );

      final result = await dataSource.getAssignments();

      expect(result.map((a) => a.code).toList(), ['TSA_1']);
      expect(adapter.captured!.method, 'GET');
      expect(adapter.captured!.path, contains('/api/v1/tasks/assignments'));
      expect(adapter.captured!.queryParameters['page'], 0);
      expect(adapter.captured!.queryParameters['size'], 500);
      // X-Staff-Code is scoped to POST /tasks only (used as assignedBy on the
      // TASK_ASSIGNED notification), so a read must not carry it.
      expect(_header(adapter.captured!, 'X-Staff-Code'), isNull);
    });

    test('returns empty for an unexpected payload shape', () async {
      stub((_) => _jsonBody({'unexpected': true}));
      expect(await dataSource.getAssignments(), isEmpty);
    });

    test('sends the q search param when provided, omits it when blank', () async {
      stub((_) => _jsonBody({'data': {'items': []}}));
      await dataSource.getAssignments(q: 'report');
      expect(adapter.captured!.queryParameters['q'], 'report');

      await dataSource.getAssignments(q: '   ');
      expect(adapter.captured!.queryParameters.containsKey('q'), isFalse);
    });
  });

  group('createTask', () {
    test('POSTs the create body and parses the series response', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'code': 'TSK_9F2A1B3C4D',
            'title': 'Prepare report',
            'assigneeCount': 2,
            'version': 0,
          },
          'message': 'Task created successfully',
        }, status: 201),
      );

      final series = await dataSource.createTask(
        draft: _draft(),
        assignees: const [
          TaskAssignee(staffCode: 'STF_1'),
          TaskAssignee(staffCode: 'STF_2'),
        ],
      );

      expect(series.code, 'TSK_9F2A1B3C4D');
      expect(series.assigneeCount, 2);
      expect(adapter.captured!.method, 'POST');
      expect(adapter.captured!.path, contains('/api/v1/tasks'));
      expect(_header(adapter.captured!, 'X-Staff-Code'), 'STF_ME');
      // Tasks must be routed to the events-todo service, not any other MS.
      expect(
        adapter.captured!.uri.toString(),
        startsWith(ApiConstants.eventsTodoBaseUrl),
      );
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['title'], 'Prepare report');
      expect((body['assignees'] as List), hasLength(2));
    });

    test('throws when the response has no data payload', () async {
      stub((_) => _jsonBody({'message': 'ok'}));
      expect(
        () => dataSource.createTask(
          draft: _draft(),
          assignees: const [TaskAssignee(staffCode: 'STF_1')],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('updateTask', () {
    test('PATCHes {code} with only the provided fields', () async {
      stub(
        (_) => _jsonBody({
          'data': {'code': 'TSK_1', 'title': 'Renamed', 'version': 1},
          'message': 'Task updated successfully',
        }),
      );

      await dataSource.updateTask(code: 'TSK_1', title: 'Renamed');

      expect(adapter.captured!.method, 'PATCH');
      expect(adapter.captured!.path, contains('/api/v1/tasks/TSK_1'));
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['title'], 'Renamed');
      expect(body.containsKey('description'), isFalse);
      // No schedule passed → no recurrence/date fields on the wire.
      expect(body.containsKey('startDate'), isFalse);
      expect(body.containsKey('recurring'), isFalse);
      // X-Staff-Code is create-only.
      expect(_header(adapter.captured!, 'X-Staff-Code'), isNull);
    });

    test('serializes the schedule for a one-off when provided', () async {
      stub(
        (_) => _jsonBody({
          'data': {'code': 'TSK_1', 'title': 'x', 'version': 1},
        }),
      );

      await dataSource.updateTask(code: 'TSK_1', schedule: _draft());

      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['recurring'], isFalse);
      expect(body['startDate'], '2026-07-15');
      expect(body['dueDate'], '2026-07-17');
      expect(body['startTime'], '09:00');
      expect(body['dueTime'], '17:00');
    });

    test('serializes RRULE fields for a recurring schedule', () async {
      stub(
        (_) => _jsonBody({
          'data': {'code': 'TSK_1', 'title': 'x', 'version': 1},
        }),
      );

      final recurring = _draft().copyWith(
        recurring: true,
        recurringPattern: () => TaskRecurrence.weekly,
        startDay: () => 'MONDAY',
        recurringEndDate: () => DateTime(2026, 9, 30),
      );
      await dataSource.updateTask(code: 'TSK_1', schedule: recurring);

      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['recurring'], isTrue);
      expect(body['rruleFreq'], 'WEEKLY');
      expect(body['rruleByDay'], ['MO']);
      expect(body['rruleUntil'], '2026-09-30');
      expect(body.containsKey('startDate'), isFalse);
    });
  });

  group('deleteTask', () {
    test('DELETEs {code}', () async {
      stub((_) => _jsonBody(const <String, dynamic>{}, status: 204));
      await dataSource.deleteTask('TSK_1');
      expect(adapter.captured!.method, 'DELETE');
      expect(adapter.captured!.path, contains('/api/v1/tasks/TSK_1'));
    });

    test('treats 404 (already deleted) as success — idempotent', () async {
      stub((_) => _jsonBody({'message': 'Task not found'}, status: 404));
      // Must not throw: re-deleting an already-gone series should succeed so
      // the stale card can be cleared.
      await expectLater(dataSource.deleteTask('TSK_GONE'), completes);
    });

    test('rethrows non-404 errors', () async {
      stub((_) => _jsonBody({'message': 'boom'}, status: 500));
      await expectLater(dataSource.deleteTask('TSK_1'), throwsA(isA<Object>()));
    });
  });

  group('updateAssignmentStatus', () {
    test('PATCHes the assignment status endpoint and parses the card', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'code': 'TSA_1',
            'taskCode': 'TSK_1',
            'title': 'Prepare Q3 report',
            'assigneeCode': 'STF_1',
            'occurrenceDate': '2026-07-15',
            'dueAt': '2026-07-17T17:00:00Z',
            'priority': 'HIGH',
            'status': 'IN_PROGRESS',
          },
          'message': 'Task status updated successfully',
        }),
      );

      final card = await dataSource.updateAssignmentStatus(
        code: 'TSA_1',
        status: TaskStatus.inProgress,
      );

      expect(card.status, 'IN_PROGRESS');
      expect(adapter.captured!.method, 'PATCH');
      expect(
        adapter.captured!.path,
        contains('/api/v1/tasks/assignments/TSA_1/status'),
      );
      expect(
        (adapter.captured!.data as Map<String, dynamic>)['status'],
        'IN_PROGRESS',
      );
    });
  });
}
