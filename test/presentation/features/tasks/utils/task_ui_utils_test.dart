import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';

Task _task({
  DateTime? dueDate,
  String dueTime = '17:00',
  bool recurring = false,
  TaskRecurrence? pattern,
  String? startDay,
  double effort = 0,
}) =>
    Task(
      code: 'TSA_1',
      title: 'Task',
      startDate: DateTime.utc(2026, 7, 15),
      dueDate: dueDate ?? DateTime.utc(2026, 7, 17),
      dueTime: dueTime,
      recurring: recurring,
      recurringPattern: pattern,
      startDay: startDay,
      effort: effort,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('formatTimeOfDay', () {
    test('formats a TimeOfDay as h:mm a', () {
      expect(TaskUiUtils.formatTimeOfDay(const TimeOfDay(hour: 13, minute: 5)),
          '1:05 PM');
      expect(TaskUiUtils.formatTimeOfDay(const TimeOfDay(hour: 0, minute: 0)),
          '12:00 AM');
    });
  });

  group('dueLabelInZone', () {
    test('converts the UTC wire moment to the school-local wall clock', () {
      // 21:00 UTC on Jul 16 is EDT (UTC-4) -> 5:00 PM Boston, still Jul 16.
      final label = TaskUiUtils.dueLabelInZone(
        _task(dueDate: DateTime.utc(2026, 7, 16), dueTime: '21:00'),
        'America/New_York',
      );
      expect(label, 'Jul 16 • 5:00 PM');
    });

    test('rolls the local calendar date back across midnight', () {
      // 01:00 UTC on Jul 16 is EDT -> 9:00 PM Boston on Jul 15.
      final label = TaskUiUtils.dueLabelInZone(
        _task(dueDate: DateTime.utc(2026, 7, 16), dueTime: '01:00'),
        'America/New_York',
      );
      expect(label, 'Jul 15 • 9:00 PM');
    });
  });

  group('recurrenceLabel', () {
    test('"Does not repeat" for a one-off', () {
      expect(TaskUiUtils.recurrenceLabel(_task()), 'Does not repeat');
    });

    test('"Does not repeat" when recurring but no pattern', () {
      expect(
        TaskUiUtils.recurrenceLabel(_task(recurring: true)),
        'Does not repeat',
      );
    });

    test('daily', () {
      expect(
        TaskUiUtils.recurrenceLabel(
            _task(recurring: true, pattern: TaskRecurrence.daily)),
        'Repeats daily',
      );
    });

    test('weekly with a title-cased day', () {
      expect(
        TaskUiUtils.recurrenceLabel(_task(
            recurring: true,
            pattern: TaskRecurrence.weekly,
            startDay: 'MONDAY')),
        'Repeats weekly • Monday',
      );
    });

    test('weekly without a day', () {
      expect(
        TaskUiUtils.recurrenceLabel(
            _task(recurring: true, pattern: TaskRecurrence.weekly)),
        'Repeats weekly',
      );
    });

    test('monthly with a day-of-month', () {
      expect(
        TaskUiUtils.recurrenceLabel(_task(
            recurring: true, pattern: TaskRecurrence.monthly, startDay: '15')),
        'Repeats monthly • day 15',
      );
    });

    test('monthly without a day', () {
      expect(
        TaskUiUtils.recurrenceLabel(
            _task(recurring: true, pattern: TaskRecurrence.monthly)),
        'Repeats monthly',
      );
    });
  });

  group('effortLabel', () {
    test('empty for zero or negative', () {
      expect(TaskUiUtils.effortLabel(0), '');
      expect(TaskUiUtils.effortLabel(-2), '');
    });

    test('singular "hr" for exactly 1', () {
      expect(TaskUiUtils.effortLabel(1), '1 hr');
    });

    test('plural "hrs" for whole numbers > 1, rendered without a decimal', () {
      expect(TaskUiUtils.effortLabel(2), '2 hrs');
    });

    test('renders a fractional value with its decimal', () {
      expect(TaskUiUtils.effortLabel(2.5), '2.5 hrs');
    });
  });
}
