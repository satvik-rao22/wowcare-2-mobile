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
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';

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
    test('GETs the flat endpoint with pagination and unwraps data.items',
        () async {
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
            'size': 100,
          },
        }),
      );

      final result = await dataSource.getAssignments(
        const TaskQuery(page: 0, size: 100),
      );

      expect(result.map((a) => a.code).toList(), ['TSA_1']);
      expect(adapter.captured!.method, 'GET');
      expect(adapter.captured!.path, contains('/api/v1/tasks/assignments'));
      expect(adapter.captured!.queryParameters['page'], 0);
      expect(adapter.captured!.queryParameters['size'], 100);
      // X-Staff-Code is scoped to POST /tasks only, so a read must not carry it.
      expect(_header(adapter.captured!, 'X-Staff-Code'), isNull);
    });

    test('returns empty for an unexpected payload shape', () async {
      stub((_) => _jsonBody({'unexpected': true}));
      expect(await dataSource.getAssignments(const TaskQuery()), isEmpty);
    });

    test('serializes multi-select filters as repeated query keys', () async {
      stub((_) => _jsonBody({'data': {'items': []}}));
      await dataSource.getAssignments(const TaskQuery(
        assigneeCodes: ['STF_1', 'STF_2'],
        priorities: [TaskPriority.high],
        statuses: [TaskStatus.toDo, TaskStatus.inProgress],
        overdue: true,
        query: 'report',
      ));

      // ListFormat.multi ⇒ `assigneeCodes=STF_1&assigneeCodes=STF_2`.
      final uri = adapter.captured!.uri.toString();
      expect(uri, contains('assigneeCodes=STF_1'));
      expect(uri, contains('assigneeCodes=STF_2'));
      expect(uri, contains('statuses=TO_DO'));
      expect(uri, contains('statuses=IN_PROGRESS'));
      expect(uri, contains('priorities=HIGH'));
      expect(uri, contains('overdue=true'));
      expect(uri, contains('q=report'));
    });
  });

  group('getTaskSeries (§2)', () {
    test('GETs /tasks with the series filters and parses the page', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'items': [
              {'code': 'TSK_1', 'title': 'A', 'recurringFlag': false},
            ],
            'page': 0,
            'size': 20,
            'totalElements': 1,
            'totalPages': 1,
          },
        }),
      );

      final page = await dataSource.getTaskSeries(
        seriesStatus: TaskSeriesStatus.active,
        recurring: false,
        q: 'report',
      );

      expect(page.items.single.code, 'TSK_1');
      expect(adapter.captured!.method, 'GET');
      expect(adapter.captured!.path, endsWith('/api/v1/tasks'));
      expect(adapter.captured!.queryParameters['seriesStatus'], 'ACTIVE');
      expect(adapter.captured!.queryParameters['recurring'], false);
      expect(adapter.captured!.queryParameters['q'], 'report');
    });
  });

  group('getBoard (§6)', () {
    test('GETs /tasks/board and groups the columns', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'columns': {
              'TO_DO': {
                'items': [
                  {
                    'code': 'TSA_1',
                    'taskCode': 'TSK_1',
                    'title': 'A',
                    'occurrenceDate': '2026-07-15',
                    'dueAt': '2026-07-17T17:00:00Z',
                    'status': 'TO_DO',
                  },
                ],
                'totalElements': 1,
                'totalPages': 1,
              },
              'IN_PROGRESS': {'items': []},
              'COMPLETED': {'items': []},
            },
          },
        }),
      );

      final board = await dataSource.getBoard(const TaskQuery());

      expect(board.toDo.cards.single.code, 'TSA_1');
      expect(board.inProgress.cards, isEmpty);
      expect(adapter.captured!.path, contains('/api/v1/tasks/board'));
    });
  });

  group('createTask', () {
    test('POSTs the create body with staff code and parses the series',
        () async {
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
        holidayPolicy: TaskHolidayPolicy.keep,
        assetCodes: const ['AST_1'],
      );

      expect(series.code, 'TSK_9F2A1B3C4D');
      expect(series.assigneeCount, 2);
      expect(adapter.captured!.method, 'POST');
      expect(adapter.captured!.path, endsWith('/api/v1/tasks'));
      expect(_header(adapter.captured!, 'X-Staff-Code'), 'STF_ME');
      expect(
        adapter.captured!.uri.toString(),
        startsWith(ApiConstants.eventsTodoBaseUrl),
      );
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['title'], 'Prepare report');
      expect((body['assignees'] as List), hasLength(2));
      expect(body['holidayPolicy'], 'KEEP');
      expect(body['assetCodes'], ['AST_1']);
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
      expect(body.containsKey('startDate'), isFalse);
      expect(body.containsKey('recurring'), isFalse);
      expect(_header(adapter.captured!, 'X-Staff-Code'), isNull);
    });

    test('sends assetCodes and parentTaskCode when provided (§3c)', () async {
      stub((_) => _jsonBody({'data': {'code': 'TSK_1', 'title': 'x'}}));
      await dataSource.updateTask(
        code: 'TSK_1',
        assetCodes: const ['AST_1', 'AST_2'],
        parentTaskCode: '',
      );
      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['assetCodes'], ['AST_1', 'AST_2']);
      expect(body['parentTaskCode'], '');
    });

    test('serializes the schedule for a one-off when provided', () async {
      stub((_) => _jsonBody({'data': {'code': 'TSK_1', 'title': 'x'}}));
      await dataSource.updateTask(code: 'TSK_1', schedule: _draft());

      final body = adapter.captured!.data as Map<String, dynamic>;
      expect(body['recurring'], isFalse);
      expect(body['startDate'], '2026-07-15');
      expect(body['dueDate'], '2026-07-17');
      expect(body['startTime'], '09:00');
      expect(body['dueTime'], '17:00');
    });

    test('serializes RRULE fields for a recurring schedule', () async {
      stub((_) => _jsonBody({'data': {'code': 'TSK_1', 'title': 'x'}}));
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
      await expectLater(dataSource.deleteTask('TSK_GONE'), completes);
    });

    test('rethrows non-404 errors', () async {
      stub((_) => _jsonBody({'message': 'boom'}, status: 500));
      await expectLater(dataSource.deleteTask('TSK_1'), throwsA(isA<Object>()));
    });
  });

  group('removeAssignee (§4a)', () {
    test('DELETEs the roster assignee endpoint', () async {
      stub((_) => _jsonBody(const <String, dynamic>{}, status: 204));
      await dataSource.removeAssignee(code: 'TSK_1', staffCode: 'STF_4D5E6F');
      expect(adapter.captured!.method, 'DELETE');
      expect(
        adapter.captured!.path,
        contains('/api/v1/tasks/TSK_1/assignees/STF_4D5E6F'),
      );
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

  group('createUploadSession (§8)', () {
    test('POSTs /tasks/upload-session and parses the session', () async {
      stub(
        (_) => _jsonBody({
          'data': {
            'sessionCode': 'SES_1A2B3C',
            'sessionStatus': 'OPEN',
            'documentApiBasePath': '/document-ms/api/v1',
          },
          'message': 'Task upload session created',
        }, status: 201),
      );

      final session = await dataSource.createUploadSession();

      expect(session.sessionCode, 'SES_1A2B3C');
      expect(session.documentApiBasePath, '/document-ms/api/v1');
      expect(adapter.captured!.method, 'POST');
      expect(adapter.captured!.path, contains('/api/v1/tasks/upload-session'));
    });
  });
}
