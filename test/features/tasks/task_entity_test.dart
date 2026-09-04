import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';

Task _task({
  TaskStatus status = TaskStatus.toDo,
  DateTime? dueDate,
  String dueTime = '17:00',
}) =>
    Task(
      code: 'TSA_1',
      title: 'Task',
      status: status,
      startDate: DateTime.utc(2026, 7, 15),
      dueDate: dueDate ?? DateTime.utc(2026, 7, 17),
      dueTime: dueTime,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  group('Task.dueAt', () {
    test('combines dueDate + HH:mm dueTime into a UTC instant', () {
      final at = _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: '14:30').dueAt;
      expect(at, DateTime.utc(2026, 7, 17, 14, 30));
      expect(at.isUtc, isTrue);
    });

    test('falls back to 17:00 when dueTime is malformed', () {
      expect(
        _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: 'garbage').dueAt,
        DateTime.utc(2026, 7, 17, 17, 0),
      );
    });

    test('falls back to :00 minute when the minute is unparseable', () {
      expect(
        _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: '09:zz').dueAt,
        DateTime.utc(2026, 7, 17, 9, 0),
      );
    });

    test('falls back to 17:00 when the hour is unparseable', () {
      expect(
        _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: 'zz:30').dueAt,
        DateTime.utc(2026, 7, 17, 17, 30),
      );
    });
  });

  group('Task.isOverdueAt', () {
    final now = DateTime.utc(2026, 7, 17, 12, 0);

    test('is overdue when the due instant has passed and not completed', () {
      final task = _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: '09:00');
      expect(task.isOverdueAt(now), isTrue);
    });

    test('is not overdue when the due instant is still in the future', () {
      final task = _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: '18:00');
      expect(task.isOverdueAt(now), isFalse);
    });

    test('a completed task is never overdue even past its due instant', () {
      final task = _task(
        status: TaskStatus.completed,
        dueDate: DateTime.utc(2026, 7, 17),
        dueTime: '09:00',
      );
      expect(task.isOverdueAt(now), isFalse);
    });

    test('a due instant exactly equal to now is not overdue', () {
      final task = _task(dueDate: DateTime.utc(2026, 7, 17), dueTime: '12:00');
      expect(task.isOverdueAt(now), isFalse);
    });
  });

  group('TaskStatus.fromValue', () {
    test('maps known codes', () {
      expect(TaskStatus.fromValue('TO_DO'), TaskStatus.toDo);
      expect(TaskStatus.fromValue('IN_PROGRESS'), TaskStatus.inProgress);
      expect(TaskStatus.fromValue('COMPLETED'), TaskStatus.completed);
    });

    test('normalizes spaces and case', () {
      expect(TaskStatus.fromValue('in progress'), TaskStatus.inProgress);
    });

    test('defaults to toDo for null/unknown', () {
      expect(TaskStatus.fromValue(null), TaskStatus.toDo);
      expect(TaskStatus.fromValue('WHATEVER'), TaskStatus.toDo);
    });
  });

  group('TaskPriority.fromValue', () {
    test('maps known codes and defaults to medium', () {
      expect(TaskPriority.fromValue('low'), TaskPriority.low);
      expect(TaskPriority.fromValue('HIGH'), TaskPriority.high);
      expect(TaskPriority.fromValue(null), TaskPriority.medium);
      expect(TaskPriority.fromValue('???'), TaskPriority.medium);
    });
  });

  group('TaskHolidayPolicy.fromValue', () {
    test('maps known codes and defaults to skip', () {
      expect(TaskHolidayPolicy.fromValue('KEEP'), TaskHolidayPolicy.keep);
      expect(TaskHolidayPolicy.fromValue('skip'), TaskHolidayPolicy.skip);
      expect(TaskHolidayPolicy.fromValue(null), TaskHolidayPolicy.skip);
      expect(TaskHolidayPolicy.fromValue('x'), TaskHolidayPolicy.skip);
    });
  });

  group('TaskRecurrence.fromValue', () {
    test('maps known codes', () {
      expect(TaskRecurrence.fromValue('DAILY'), TaskRecurrence.daily);
      expect(TaskRecurrence.fromValue('weekly'), TaskRecurrence.weekly);
      expect(TaskRecurrence.fromValue('MONTHLY'), TaskRecurrence.monthly);
    });

    test('returns null for null/unknown (non-recurring)', () {
      expect(TaskRecurrence.fromValue(null), isNull);
      expect(TaskRecurrence.fromValue(''), isNull);
      expect(TaskRecurrence.fromValue('YEARLY'), isNull);
    });
  });

  group('Task.copyWith function-wrapped nullable setters', () {
    test('leaves a nullable field untouched when its setter is omitted', () {
      final base = _task().copyWith(
        recurring: true,
        recurringPattern: () => TaskRecurrence.weekly,
        startDay: () => 'MONDAY',
      );
      final copy = base.copyWith(title: 'Renamed');
      expect(copy.title, 'Renamed');
      expect(copy.recurringPattern, TaskRecurrence.weekly);
      expect(copy.startDay, 'MONDAY');
    });

    test('clears a nullable field when the setter returns null', () {
      final base = _task().copyWith(
        recurringPattern: () => TaskRecurrence.weekly,
        recurringEndDate: () => DateTime.utc(2026, 8, 1),
        startDay: () => 'MONDAY',
      );
      final cleared = base.copyWith(
        recurringPattern: () => null,
        recurringEndDate: () => null,
        startDay: () => null,
      );
      expect(cleared.recurringPattern, isNull);
      expect(cleared.recurringEndDate, isNull);
      expect(cleared.startDay, isNull);
    });
  });
}
