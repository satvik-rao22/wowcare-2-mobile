import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_schedule_utils.dart';

Task _card() => Task(
      code: 'TSA_1',
      taskCode: 'TSK_1',
      title: 'Recur Weird time',
      // The assignment payload (§5b) carries its own real per-occurrence
      // start/due time — already correct, and must not be overwritten by the
      // series' (possibly stale) template time.
      startTime: '08:00',
      dueTime: '17:38',
      startDate: DateTime(2026, 7, 22),
      dueDate: DateTime(2026, 7, 22),
      createdAt: DateTime(2026, 7, 22),
      updatedAt: DateTime(2026, 7, 22),
    );

void main() {
  group('hhmm', () {
    test('normalizes HH:mm:ss to HH:mm', () {
      expect(TaskScheduleUtils.hhmm('07:23:00'), '07:23');
    });
    test('passes through HH:mm', () {
      expect(TaskScheduleUtils.hhmm('7:5'), '07:05');
    });
    test('returns null for empty or malformed input', () {
      expect(TaskScheduleUtils.hhmm(''), isNull);
      expect(TaskScheduleUtils.hhmm('nonsense'), isNull);
      expect(TaskScheduleUtils.hhmm('12'), isNull);
    });
  });

  group('weekdayFromAbbr', () {
    test('maps known abbreviations', () {
      expect(TaskScheduleUtils.weekdayFromAbbr('MO'), 'MONDAY');
      expect(TaskScheduleUtils.weekdayFromAbbr('su'), 'SUNDAY');
    });
    test('returns null for an unknown token', () {
      expect(TaskScheduleUtils.weekdayFromAbbr('XX'), isNull);
    });
  });

  group('seriesStartDay', () {
    test('weekly → first weekday name', () {
      const series = TaskSeries(
        code: 'TSK_1',
        title: 'x',
        recurring: true,
        recurrencePattern: TaskRecurrence.weekly,
        recurrenceByDay: ['WE', 'FR'],
      );
      expect(TaskScheduleUtils.seriesStartDay(series), 'WEDNESDAY');
    });
    test('monthly → day-of-month string', () {
      const series = TaskSeries(
        code: 'TSK_1',
        title: 'x',
        recurring: true,
        recurrencePattern: TaskRecurrence.monthly,
        recurrenceByMonthday: 15,
      );
      expect(TaskScheduleUtils.seriesStartDay(series), '15');
    });
    test('daily → null', () {
      const series = TaskSeries(
        code: 'TSK_1',
        title: 'x',
        recurring: true,
        recurrencePattern: TaskRecurrence.daily,
      );
      expect(TaskScheduleUtils.seriesStartDay(series), isNull);
    });
  });

  group('withSeriesSchedule', () {
    test('keeps the card start/due time even when the series has its own', () {
      const series = TaskSeries(
        code: 'TSK_1',
        title: 'Recur Weird time',
        recurring: true,
        recurrencePattern: TaskRecurrence.daily,
        seriesStartTime: '07:23:00',
        seriesEndTime: '17:38:00',
        recurrenceUntil: null,
      );

      final merged = TaskScheduleUtils.withSeriesSchedule(_card(), series);

      // The card's real per-occurrence time (08:00) wins over the series'
      // template (07:23) — the series value may be stale after an edit that
      // only patched this occurrence.
      expect(merged.startTime, '08:00');
      expect(merged.dueTime, '17:38');
      expect(merged.recurring, isTrue);
      expect(merged.recurringPattern, TaskRecurrence.daily);
    });

    test('populates weekly recurrence fields for the "Repeats" row', () {
      const series = TaskSeries(
        code: 'TSK_1',
        title: 'x',
        recurring: true,
        recurrencePattern: TaskRecurrence.weekly,
        recurrenceByDay: ['MO'],
        seriesStartTime: '08:00:00',
        recurrenceUntil: null,
      );

      final merged = TaskScheduleUtils.withSeriesSchedule(_card(), series);
      expect(merged.recurring, isTrue);
      expect(merged.recurringPattern, TaskRecurrence.weekly);
      expect(merged.startDay, 'MONDAY');
      expect(merged.startTime, '08:00');
    });

    test('leaves the card start time untouched when the series omits one', () {
      const series = TaskSeries(
        code: 'TSK_1',
        title: 'x',
        recurring: false,
        seriesStartTime: '',
      );
      final merged = TaskScheduleUtils.withSeriesSchedule(_card(), series);
      expect(merged.startTime, '08:00'); // unchanged card value
      expect(merged.recurring, isFalse);
    });
  });
}
