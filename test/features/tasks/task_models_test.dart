import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';

void main() {
  group('TaskAssignmentModel.fromJson → toEntity', () {
    test('maps codes, splits dueAt into dueDate/dueTime, keeps taskCode', () {
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_1A2B3C4D5E',
        'taskCode': 'TSK_9F2A1B3C4D',
        'title': 'Prepare Q3 report',
        'assigneeCode': 'STF_1A2B3C',
        'occurrenceDate': '2026-07-15',
        'dueAt': '2026-07-17T17:00:00Z',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'overdue': false,
      });

      final task = model.toEntity();

      expect(task.code, 'TSA_1A2B3C4D5E');
      expect(task.taskCode, 'TSK_9F2A1B3C4D');
      expect(task.title, 'Prepare Q3 report');
      expect(task.assigneeCode, 'STF_1A2B3C');
      expect(task.status, TaskStatus.inProgress);
      expect(task.priority, TaskPriority.high);
      expect(task.startDate, DateTime(2026, 7, 15));
      // dueAt is converted to local (Fix A), so assert against the local
      // wall-clock rather than the raw UTC components (timezone-robust).
      final localDue = DateTime.parse('2026-07-17T17:00:00Z').toLocal();
      expect(task.dueDate, DateTime(localDue.year, localDue.month, localDue.day));
      expect(
        task.dueTime,
        '${localDue.hour.toString().padLeft(2, '0')}:'
        '${localDue.minute.toString().padLeft(2, '0')}',
      );
    });

    test('defaults status/priority and tolerates a missing dueAt', () {
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_X',
        'taskCode': 'TSK_X',
        'title': 'x',
        'occurrenceDate': '2026-07-15',
      });
      final task = model.toEntity();
      expect(task.status, TaskStatus.toDo);
      expect(task.priority, TaskPriority.medium);
      // dueAt falls back to the occurrence date.
      expect(task.dueDate, DateTime(2026, 7, 15));
    });

    // Fix A: a UTC `dueAt` must be converted to the device's local wall-clock
    // before being split into dueDate/dueTime, otherwise overdue math and the
    // displayed time are off by the timezone offset.
    test('converts a UTC dueAt to local before splitting date/time', () {
      const iso = '2026-07-17T17:00:00Z';
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_TZ',
        'taskCode': 'TSK_TZ',
        'title': 'x',
        'occurrenceDate': '2026-07-15',
        'dueAt': iso,
      });
      final task = model.toEntity();

      final local = DateTime.parse(iso).toLocal();
      final expectedTime = '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
      expect(task.dueTime, expectedTime);
      expect(task.dueDate, DateTime(local.year, local.month, local.day));
      // The reconstructed due moment must equal the original instant.
      expect(task.dueAt, local);
    });
  });

  group('TaskSeriesModel.fromJson', () {
    test('parses code, version and assignee count (numeric or string)', () {
      final model = TaskSeriesModel.fromJson(const {
        'code': 'TSK_9F2A1B3C4D',
        'title': 'Prepare report',
        'description': 'Q3 summary',
        'recurringFlag': false,
        'seriesStatus': 'ACTIVE',
        'assigneeCount': 2,
        'version': '1',
      });
      expect(model.code, 'TSK_9F2A1B3C4D');
      expect(model.assigneeCount, 2);
      expect(model.version, 1);
      expect(model.seriesStatus, 'ACTIVE');
    });
  });

  group('TaskRequestBuilder.createBody', () {
    Task draft({
      bool recurring = false,
      TaskRecurrence? pattern,
      String? startDay,
      DateTime? until,
    }) =>
        Task(
          code: '',
          title: 'Prepare report',
          description: 'Q3 attendance summary',
          priority: TaskPriority.high,
          effort: 3.5,
          startDate: DateTime(2026, 7, 15),
          startTime: '09:00',
          dueDate: DateTime(2026, 7, 17),
          dueTime: '17:00',
          recurring: recurring,
          recurringPattern: pattern,
          recurringEndDate: until,
          startDay: startDay,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    test('one-off: sends concrete dates, priority, effort and roster', () {
      final body = TaskRequestBuilder.createBody(
        draft: draft(),
        assignees: const [
          TaskAssignee(staffCode: 'STF_1A2B3C'),
          TaskAssignee(staffCode: 'STF_4D5E6F', priority: TaskPriority.medium),
        ],
      );

      expect(body['recurring'], false);
      expect(body['title'], 'Prepare report');
      expect(body['description'], 'Q3 attendance summary');
      expect(body['priority'], 'HIGH');
      expect(body['effort'], 3.5);
      expect(body['startDate'], '2026-07-15');
      expect(body['dueDate'], '2026-07-17');
      expect(body['startTime'], '09:00');
      expect(body['dueTime'], '17:00');
      final assignees = body['assignees'] as List;
      expect(assignees, hasLength(2));
      expect((assignees[0] as Map)['staffCode'], 'STF_1A2B3C');
      expect((assignees[0] as Map).containsKey('priority'), isFalse);
      expect((assignees[1] as Map)['priority'], 'MEDIUM');
      // Dates are omitted for recurring only; no assetCodes when none given.
      expect(body.containsKey('assetCodes'), isFalse);
      expect(body.containsKey('rruleFreq'), isFalse);
    });

    test('weekly: sends rruleFreq/rruleByDay and omits concrete dates', () {
      final body = TaskRequestBuilder.createBody(
        draft: draft(
          recurring: true,
          pattern: TaskRecurrence.weekly,
          startDay: 'MONDAY',
          until: DateTime(2026, 9, 30),
        ),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
      );

      expect(body['recurring'], true);
      expect(body['rruleFreq'], 'WEEKLY');
      expect(body['rruleByDay'], ['MO']);
      expect(body['rruleUntil'], '2026-09-30');
      expect(body.containsKey('startDate'), isFalse);
      expect(body.containsKey('dueDate'), isFalse);
    });

    test('monthly: sends rruleByMonthday from the day-of-month startDay', () {
      final body = TaskRequestBuilder.createBody(
        draft: draft(
          recurring: true,
          pattern: TaskRecurrence.monthly,
          startDay: '15',
        ),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
      );
      expect(body['rruleFreq'], 'MONTHLY');
      expect(body['rruleByMonthday'], 15);
      expect(body.containsKey('rruleByDay'), isFalse);
    });

    test('includes assetCodes only when present', () {
      final body = TaskRequestBuilder.createBody(
        draft: draft(),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
        assetCodes: const ['AST_9F2A1B'],
      );
      expect(body['assetCodes'], ['AST_9F2A1B']);
    });

    // Fix D: holidayPolicy is sent on create only when supplied; omitted lets
    // the server default to SKIP.
    test('sends holidayPolicy only when supplied', () {
      final withPolicy = TaskRequestBuilder.createBody(
        draft: draft(),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
        holidayPolicy: TaskHolidayPolicy.keep,
      );
      expect(withPolicy['holidayPolicy'], 'KEEP');

      final without = TaskRequestBuilder.createBody(
        draft: draft(),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
      );
      expect(without.containsKey('holidayPolicy'), isFalse);
    });
  });

  group('TaskRequestBuilder.updateBody', () {
    test('sends only the provided fields', () {
      final body = TaskRequestBuilder.updateBody(
        title: 'Prepare Q3 report',
        holidayPolicy: TaskHolidayPolicy.keep,
        assignees: const [TaskAssignee(staffCode: 'STF_7A8B9C', priority: TaskPriority.high)],
      );
      expect(body['title'], 'Prepare Q3 report');
      expect(body['holidayPolicy'], 'KEEP');
      expect(body.containsKey('description'), isFalse);
      expect((body['assignees'] as List).single, {
        'staffCode': 'STF_7A8B9C',
        'priority': 'HIGH',
      });
    });

    test('is empty when nothing is provided', () {
      expect(TaskRequestBuilder.updateBody(), isEmpty);
    });

    // Fix B (§3c): assetCodes full-replace and parentTaskCode re-parent.
    test('sends assetCodes as a full replace (including an empty list)', () {
      expect(
        TaskRequestBuilder.updateBody(assetCodes: const ['AST_1', 'AST_2'])[
            'assetCodes'],
        ['AST_1', 'AST_2'],
      );
      // An empty list is meaningful (clears all attachments) → must be sent.
      final cleared = TaskRequestBuilder.updateBody(assetCodes: const []);
      expect(cleared.containsKey('assetCodes'), isTrue);
      expect(cleared['assetCodes'], isEmpty);
      // Null means "leave unchanged" → omitted.
      expect(TaskRequestBuilder.updateBody().containsKey('assetCodes'), isFalse);
    });

    test('sends parentTaskCode, including "" to clear the parent', () {
      expect(
        TaskRequestBuilder.updateBody(parentTaskCode: 'TSK_PARENT01')[
            'parentTaskCode'],
        'TSK_PARENT01',
      );
      // "" clears an existing parent and must reach the wire (not omitted).
      final cleared = TaskRequestBuilder.updateBody(parentTaskCode: '');
      expect(cleared.containsKey('parentTaskCode'), isTrue);
      expect(cleared['parentTaskCode'], '');
      // Null leaves it unchanged.
      expect(
        TaskRequestBuilder.updateBody().containsKey('parentTaskCode'),
        isFalse,
      );
    });

    test('serializes the schedule when a task is provided (§3 parity)', () {
      final body = TaskRequestBuilder.updateBody(
        schedule: Task(
          code: '',
          title: 'x',
          startDate: DateTime(2026, 7, 15),
          startTime: '08:00',
          dueDate: DateTime(2026, 7, 17),
          dueTime: '10:00',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      expect(body['recurring'], false);
      expect(body['startDate'], '2026-07-15');
      expect(body['dueDate'], '2026-07-17');
      expect(body['startTime'], '08:00');
      expect(body['dueTime'], '10:00');
    });
  });

  test('statusBody sends the uppercase status code', () {
    expect(
      TaskRequestBuilder.statusBody(TaskStatus.completed),
      {'status': 'COMPLETED'},
    );
  });

  group('TaskSeriesModel.toSeries (§2 list row)', () {
    test('maps list fields to the TaskSeries domain entity', () {
      final series = TaskSeriesModel.fromJson(const {
        'code': 'TSK_2E7C1A0B9F',
        'title': 'Water classroom plants',
        'recurringFlag': true,
        'rruleFreq': 'WEEKLY',
        'seriesStartDate': '2026-07-15',
        'seriesStatus': 'ACTIVE',
        'nextOccurrenceDate': '2026-07-15',
        'nextOccurrenceStatus': 'SCHEDULED',
        'version': 0,
      }).toSeries();

      expect(series.code, 'TSK_2E7C1A0B9F');
      expect(series.title, 'Water classroom plants');
      expect(series.recurring, isTrue);
      expect(series.recurrencePattern, TaskRecurrence.weekly);
      expect(series.seriesStartDate, DateTime(2026, 7, 15));
      expect(series.seriesStatus, TaskSeriesStatus.active);
      expect(series.nextOccurrenceStatus, 'SCHEDULED');
    });

    test('leaves recurrencePattern null for a one-off series', () {
      final series = TaskSeriesModel.fromJson(const {
        'code': 'TSK_1',
        'title': 'Prepare report',
        'recurringFlag': false,
        'rruleFreq': null,
        'seriesStatus': 'ENDED',
      }).toSeries();
      expect(series.recurring, isFalse);
      expect(series.recurrencePattern, isNull);
      expect(series.seriesStatus, TaskSeriesStatus.ended);
    });
  });

  group('TaskRequestBuilder.assignmentQueryParams (§6/§7)', () {
    test('drops empty filters and keeps only active ones', () {
      final params = TaskRequestBuilder.assignmentQueryParams(const TaskQuery());
      expect(params['page'], 0);
      expect(params['size'], 20);
      expect(params.containsKey('assigneeCodes'), isFalse);
      expect(params.containsKey('priorities'), isFalse);
      expect(params.containsKey('statuses'), isFalse);
      expect(params.containsKey('overdue'), isFalse);
      expect(params.containsKey('q'), isFalse);
    });

    test('serializes multi-selects, date window, overdue and search', () {
      final params = TaskRequestBuilder.assignmentQueryParams(TaskQuery(
        assigneeCodes: const ['STF_1', 'STF_2'],
        priorities: const [TaskPriority.high, TaskPriority.medium],
        statuses: const [TaskStatus.toDo, TaskStatus.inProgress],
        fromDate: DateTime(2026, 7, 1),
        toDate: DateTime(2026, 7, 31),
        overdue: true,
        query: '  report  ',
        page: 2,
        size: 50,
      ));

      expect(params['assigneeCodes'], ['STF_1', 'STF_2']);
      expect(params['priorities'], ['HIGH', 'MEDIUM']);
      expect(params['statuses'], ['TO_DO', 'IN_PROGRESS']);
      expect(params['fromDate'], '2026-07-01');
      expect(params['toDate'], '2026-07-31');
      expect(params['overdue'], true);
      expect(params['q'], 'report');
      expect(params['page'], 2);
      expect(params['size'], 50);
    });
  });

  group('TaskRequestBuilder.seriesListQueryParams (§2)', () {
    test('includes only supplied filters', () {
      final params = TaskRequestBuilder.seriesListQueryParams(
        seriesStatus: TaskSeriesStatus.active,
        recurring: false,
        q: 'report',
        page: 1,
        size: 20,
      );
      expect(params['seriesStatus'], 'ACTIVE');
      expect(params['recurring'], false);
      expect(params['q'], 'report');
      expect(params['page'], 1);
      expect(params['size'], 20);

      final bare = TaskRequestBuilder.seriesListQueryParams();
      expect(bare.keys.toSet(), {'page', 'size'});
    });
  });

  group('TaskResponseParser', () {
    test('seriesPage unwraps items and pagination (§2)', () {
      final page = TaskResponseParser.seriesPage(const {
        'data': {
          'items': [
            {'code': 'TSK_1', 'title': 'A', 'recurringFlag': false},
            {'code': 'TSK_2', 'title': 'B', 'recurringFlag': true, 'rruleFreq': 'WEEKLY'},
            {'title': 'no code — dropped'},
          ],
          'page': 0,
          'size': 20,
          'totalElements': 2,
          'totalPages': 1,
        },
      });
      expect(page.items.map((s) => s.code), ['TSK_1', 'TSK_2']);
      expect(page.totalElements, 2);
      expect(page.totalPages, 1);
    });

    test('seriesPage degrades to an empty page on a bad payload', () {
      final page = TaskResponseParser.seriesPage({'unexpected': true});
      expect(page.items, isEmpty);
      expect(page.totalElements, 0);
    });

    test('board groups cards into the three columns with pagination (§6)', () {
      final board = TaskResponseParser.board(const {
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
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
            },
            'IN_PROGRESS': {'items': [], 'totalElements': 0, 'totalPages': 0},
            'COMPLETED': {'items': [], 'totalElements': 0, 'totalPages': 0},
          },
        },
      });
      expect(board.toDo.cards.single.code, 'TSA_1');
      expect(board.toDo.totalElements, 1);
      expect(board.inProgress.cards, isEmpty);
      expect(board.completed.cards, isEmpty);
      expect(board.column(TaskStatus.toDo).cards.single.code, 'TSA_1');
    });

    test('board returns empty columns when the envelope is malformed', () {
      final board = TaskResponseParser.board({'data': {}});
      expect(board.toDo.cards, isEmpty);
      expect(board.inProgress.cards, isEmpty);
      expect(board.completed.cards, isEmpty);
    });

    test('uploadSession parses code and falls back on missing base path', () {
      final session = TaskResponseParser.uploadSession(
        const {
          'data': {'sessionCode': 'SES_1A2B3C', 'sessionStatus': 'OPEN'},
        },
        fallbackDocumentBasePath: '/document-ms/api/v1',
      );
      expect(session.sessionCode, 'SES_1A2B3C');
      expect(session.documentApiBasePath, '/document-ms/api/v1');

      final explicit = TaskResponseParser.uploadSession(
        const {
          'data': {
            'sessionCode': 'SES_2',
            'documentApiBasePath': '/api/v1/document',
          },
        },
        fallbackDocumentBasePath: '/document-ms/api/v1',
      );
      expect(explicit.documentApiBasePath, '/api/v1/document');
    });

    test('uploadSession throws when the session code is missing', () {
      expect(
        () => TaskResponseParser.uploadSession(
          const {'data': <String, dynamic>{}},
          fallbackDocumentBasePath: '/x',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
