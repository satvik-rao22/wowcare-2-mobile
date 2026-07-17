import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';

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
      expect(task.dueDate, DateTime(2026, 7, 17));
      expect(task.dueTime, '17:00');
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
}
