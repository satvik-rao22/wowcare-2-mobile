import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';

void main() {
  // The creator is what the staff "By Me" scope and the "Created By" filter
  // match on. It isn't in the documented §5a/§6/§7 item shape, so the spelling
  // the service actually uses is accepted in either form rather than the whole
  // scope silently reading as empty.
  group('TaskAssignmentModel — creator', () {
    Task parse(Map<String, dynamic> extra) => TaskAssignmentModel.fromJson({
          'code': 'TSA_1',
          'taskCode': 'TSK_1',
          'title': 'x',
          'occurrenceDate': '2026-07-15',
          ...extra,
        }).toEntity();

    test('reads the createdBy spelling', () {
      final task = parse(const {
        'createdBy': 'STF_CREATOR',
        'createdByName': 'Alice Ng',
      });
      expect(task.createdBy, 'STF_CREATOR');
      expect(task.createdByName, 'Alice Ng');
    });

    test('reads the assignedBy spelling', () {
      // `X-Staff-Code` on create is documented as the `assignedBy` of the
      // TASK_ASSIGNED notification, so the read model may echo that name.
      final task = parse(const {
        'assignedBy': 'STF_CREATOR',
        'assignedByName': 'Alice Ng',
      });
      expect(task.createdBy, 'STF_CREATOR');
      expect(task.createdByName, 'Alice Ng');
    });

    test('reads the Code-suffixed spellings', () {
      expect(parse(const {'createdByCode': 'STF_A'}).createdBy, 'STF_A');
      expect(parse(const {'assignedByCode': 'STF_B'}).createdBy, 'STF_B');
    });

    test('prefers createdBy when several spellings are present', () {
      final task = parse(const {
        'createdBy': 'STF_WINS',
        'assignedBy': 'STF_LOSES',
      });
      expect(task.createdBy, 'STF_WINS');
    });

    test('trims and ignores blank values', () {
      expect(parse(const {'createdBy': '  STF_A  '}).createdBy, 'STF_A');
      expect(
        parse(const {'createdBy': '   ', 'assignedBy': 'STF_B'}).createdBy,
        'STF_B',
      );
    });
  });

  group('TaskAssignmentModel.fromJson → toEntity', () {
    test('maps codes and the split schedule fields, keeps taskCode', () {
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_1A2B3C4D5E',
        'taskCode': 'TSK_9F2A1B3C4D',
        'title': 'Prepare Q3 report',
        'description': 'Q3 attendance summary for the board meeting',
        'assigneeCode': 'STF_1A2B3C',
        'occurrenceDate': '2026-07-15',
        'startTime': '09:00:00',
        'dueDate': '2026-07-17',
        'dueTime': '17:00:00',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'effort': 3.5,
        'overdue': false,
      });

      final task = model.toEntity();

      expect(task.code, 'TSA_1A2B3C4D5E');
      expect(task.taskCode, 'TSK_9F2A1B3C4D');
      expect(task.title, 'Prepare Q3 report');
      // description + effort now travel on the assignment payload (§5a/§6/§7).
      expect(task.description, 'Q3 attendance summary for the board meeting');
      expect(task.effort, 3.5);
      expect(task.assigneeCode, 'STF_1A2B3C');
      expect(task.status, TaskStatus.inProgress);
      expect(task.priority, TaskPriority.high);
      expect(task.startDate, DateTime(2026, 7, 15));
      // `HH:mm:ss` wall-clock times are normalized to the `HH:mm` the UI reads.
      expect(task.startTime, '09:00');
      expect(task.dueDate, DateTime(2026, 7, 17));
      expect(task.dueTime, '17:00');
    });

    test('defaults status/priority and tolerates missing schedule parts', () {
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_X',
        'taskCode': 'TSK_X',
        'title': 'x',
        'occurrenceDate': '2026-07-15',
      });
      final task = model.toEntity();
      expect(task.status, TaskStatus.toDo);
      expect(task.priority, TaskPriority.medium);
      // No creator on the payload → empty, and the "By Me" scope simply finds
      // nothing rather than mis-attributing the task to the current user.
      expect(task.createdBy, isEmpty);
      expect(task.createdByName, isEmpty);
      // The due date falls back to the occurrence date; times to the entity
      // defaults, when the payload omits them.
      expect(task.dueDate, DateTime(2026, 7, 15));
      expect(task.startTime, '09:00');
      expect(task.dueTime, '17:00');
    });

    test('reads dueTime as a literal wall-clock (no timezone shift)', () {
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_TZ',
        'taskCode': 'TSK_TZ',
        'title': 'x',
        'occurrenceDate': '2026-07-22',
        'dueDate': '2026-07-22',
        'dueTime': '17:38:00',
      });
      final task = model.toEntity();

      // Exactly the entered wall-clock, on any device timezone.
      expect(task.dueTime, '17:38');
      expect(task.dueDate, DateTime(2026, 7, 22));
    });

    // A due date that rolls past the occurrence date (e.g. a next-day due)
    // keeps its own calendar day, independent of the occurrence day.
    test('keeps the due calendar day when it differs from occurrenceDate', () {
      final model = TaskAssignmentModel.fromJson(const {
        'code': 'TSA_ROLL',
        'taskCode': 'TSK_ROLL',
        'title': 'x',
        'occurrenceDate': '2026-07-22',
        'dueDate': '2026-07-23',
        'dueTime': '13:00:00',
      });
      final task = model.toEntity();
      expect(task.dueDate, DateTime(2026, 7, 23));
      expect(task.dueTime, '13:00');
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
      expect(body.containsKey('rrule'), isFalse);
    });

    test('weekly: sends a single rrule string and omits concrete dates', () {
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
      // The API wants ONE RFC 5545 string, not decomposed rruleFreq/
      // rruleInterval/rruleByDay/rruleUntil fields.
      expect(body['rrule'], 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO;UNTIL=20260930');
      expect(body.containsKey('rruleFreq'), isFalse);
      expect(body.containsKey('startDate'), isFalse);
      expect(body.containsKey('dueDate'), isFalse);
    });

    test('monthly: embeds BYMONTHDAY from the day-of-month startDay', () {
      final body = TaskRequestBuilder.createBody(
        draft: draft(
          recurring: true,
          pattern: TaskRecurrence.monthly,
          startDay: '15',
          until: DateTime(2026, 12, 31),
        ),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
      );
      expect(
        body['rrule'],
        'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15;UNTIL=20261231',
      );
    });

    test('recurring with no end date omits UNTIL from the rrule string', () {
      final body = TaskRequestBuilder.createBody(
        draft: draft(
          recurring: true,
          pattern: TaskRecurrence.monthly,
          startDay: '1',
        ),
        assignees: const [TaskAssignee(staffCode: 'STF_1A2B3C')],
      );
      expect(body['rrule'], 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1');
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
                  'dueDate': '2026-07-17',
                  'dueTime': '17:00:00',
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

    test('occurrenceList parses the bare data array (§11a)', () {
      final list = TaskResponseParser.occurrenceList(const {
        'data': [
          {
            'code': 'TOC_1',
            'taskCode': 'TSK_1',
            'sequenceNumber': 1,
            'originalStartDate': '2026-07-15',
            'status': 'SCHEDULED',
          },
          // No code — filtered out.
          {'taskCode': 'TSK_1', 'originalStartDate': '2026-07-17'},
        ],
      });
      expect(list.map((o) => o.code).toList(), ['TOC_1']);
    });

    test('occurrence throws on a malformed payload (§11b)', () {
      expect(
        () => TaskResponseParser.occurrence(const {'data': 'nope'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TaskSeriesModel detail (§2a)', () {
    test('parses the recurrence breakdown, times and comma-joined byDay', () {
      final series = TaskSeriesModel.fromJson(const {
        'code': 'TSK_1',
        'title': 'Water plants',
        'description': 'daily care',
        'recurringFlag': true,
        'rruleFreq': 'WEEKLY',
        'rruleInterval': 2,
        'rruleByDay': 'MO,WE,FR',
        'rruleUntil': '2026-09-30',
        'seriesStartTime': '08:30',
        'seriesEndTime': '09:00',
        'holidayPolicy': 'KEEP',
        'parentTaskCode': 'TSK_PARENT',
      }).toSeries();

      expect(series.recurrenceInterval, 2);
      expect(series.recurrenceByDay, ['MO', 'WE', 'FR']);
      expect(series.recurrenceUntil, DateTime(2026, 9, 30));
      expect(series.seriesStartTime, '08:30');
      expect(series.holidayPolicy, TaskHolidayPolicy.keep);
      expect(series.parentTaskCode, 'TSK_PARENT');
      expect(series.description, 'daily care');
    });

    test('accepts rruleByDay as a list too', () {
      final model = TaskSeriesModel.fromJson(const {
        'code': 'TSK_1',
        'title': 'x',
        'rruleByDay': ['mo', 'we'],
      });
      expect(model.rruleByDay, ['MO', 'WE']);
    });

    // The real create/update/detail (§1/§2a/§3) response carries ONE `rrule`
    // string plus a convenience `rruleUntil` — not separate rruleInterval/
    // rruleByDay/rruleByMonthday keys. This is the shape that was silently
    // unparsed before (recurrencePattern/interval/byDay all read null against
    // a real backend), breaking the edit form's recurrence prefill.
    test('parses the single rrule string from a real detail/create/update '
        'response (weekly)', () {
      final model = TaskSeriesModel.fromJson(const {
        'code': 'TSK_1',
        'title': 'Water plants',
        'recurringFlag': true,
        'rrule': 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;UNTIL=20260930',
        'rruleUntil': '2026-09-30',
      });
      expect(model.rruleFreq, 'WEEKLY');
      expect(model.rruleInterval, 2);
      expect(model.rruleByDay, ['MO', 'WE', 'FR']);
      expect(model.rruleUntil, DateTime(2026, 9, 30));
    });

    test('parses the single rrule string (monthly, BYMONTHDAY)', () {
      final model = TaskSeriesModel.fromJson(const {
        'code': 'TSK_1',
        'title': 'x',
        'recurringFlag': true,
        'rrule': 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15;UNTIL=20270331',
      });
      expect(model.rruleFreq, 'MONTHLY');
      expect(model.rruleByMonthday, 15);
      expect(model.rruleByDay, isEmpty);
      // UNTIL embedded in `rrule` is honored even without a separate
      // `rruleUntil` convenience field.
      expect(model.rruleUntil, DateTime(2027, 3, 31));
    });
  });

  group('TaskOccurrenceModel.fromJson → toEntity (§11)', () {
    test('maps identity, reschedulable window and roll-up counts', () {
      final occ = TaskOccurrenceModel.fromJson(const {
        'code': 'TOC_7B1D4E2A31',
        'taskCode': 'TSK_2E7C1A0B9F',
        'sequenceNumber': 2,
        'originalStartDate': '2026-07-17',
        'scheduledStartDate': '2026-07-18',
        'scheduledStartTime': '08:30',
        'scheduledEndTime': '09:00',
        'overrideTitle': 'Moved',
        'isModified': true,
        'status': 'CANCELLED',
        'statusReason': 'Closed',
        'assignmentTotal': 1,
        'version': 2,
      }).toEntity();

      expect(occ.code, 'TOC_7B1D4E2A31');
      expect(occ.originalStartDate, DateTime(2026, 7, 17));
      expect(occ.scheduledStartDate, DateTime(2026, 7, 18));
      expect(occ.overrideTitle, 'Moved');
      expect(occ.isModified, isTrue);
      expect(occ.status, TaskOccurrenceStatus.cancelled);
      expect(occ.statusReason, 'Closed');
      expect(occ.assignmentTotal, 1);
    });
  });

  group('TaskRequestBuilder — isolated edits', () {
    test('assigneePriorityBody sends the uppercase priority (§4b)', () {
      expect(
        TaskRequestBuilder.assigneePriorityBody(TaskPriority.high),
        {'priority': 'HIGH'},
      );
    });

    test('assignmentPatchBody sends the split schedule fields + priority (§5b)',
        () {
      final body = TaskRequestBuilder.assignmentPatchBody(
        occurrenceDate: DateTime(2026, 7, 18),
        startTime: '10:00',
        dueDate: DateTime(2026, 7, 18),
        dueTime: '17:00',
        priority: TaskPriority.high,
      );
      expect(body['occurrenceDate'], '2026-07-18');
      expect(body['startTime'], '10:00');
      expect(body['dueDate'], '2026-07-18');
      expect(body['dueTime'], '17:00');
      expect(body['priority'], 'HIGH');
      expect(body.containsKey('dueAt'), isFalse);
    });

    test('assignmentPatchBody omits unset fields', () {
      expect(TaskRequestBuilder.assignmentPatchBody(), isEmpty);
    });

    test('occurrencePatchBody sends only provided override fields (§11c)', () {
      final body = TaskRequestBuilder.occurrencePatchBody(
        scheduledStartDate: DateTime(2026, 7, 18),
        overrideTitle: '',
      );
      expect(body['scheduledStartDate'], '2026-07-18');
      // Explicit "" reaches the wire (clears the override), not dropped.
      expect(body.containsKey('overrideTitle'), isTrue);
      expect(body['overrideTitle'], '');
      expect(body.containsKey('scheduledStartTime'), isFalse);
    });
  });
}
