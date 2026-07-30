import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/recurrence_rule.dart';
import 'package:wowcare/presentation/features/events/utils/recurrence_end_policy.dart';
import 'package:wowcare/presentation/features/events/utils/recurrence_summary.dart';

void main() {
  // Calendar facts used below: Sep 15, 2026 is the THIRD Tuesday of its
  // month; Sep 29, 2026 is the LAST Tuesday.
  final start = DateTime(2026, 9, 15);

  RecurrenceRule rule({
    RecurrenceFrequency frequency = RecurrenceFrequency.weekly,
    int interval = 1,
    Set<int> daysOfWeek = const {},
    MonthlyRepeatMode monthlyMode = MonthlyRepeatMode.dayOfMonth,
    YearlyRepeatMode yearlyMode = YearlyRepeatMode.date,
    DateTime? endDate,
  }) =>
      RecurrenceRule(
        frequency: frequency,
        interval: interval,
        daysOfWeek: daysOfWeek,
        monthlyMode: monthlyMode,
        yearlyMode: yearlyMode,
        endDate: endDate ?? DateTime(2027, 12, 31),
      );

  group('RecurrenceRule.matches — daily', () {
    test('every 3 days hits only every third day', () {
      final r = rule(frequency: RecurrenceFrequency.daily, interval: 3);
      expect(r.matches(DateTime(2026, 9, 15), start), isTrue);
      expect(r.matches(DateTime(2026, 9, 16), start), isFalse);
      expect(r.matches(DateTime(2026, 9, 18), start), isTrue);
      expect(r.matches(DateTime(2026, 9, 21), start), isTrue);
    });

    test('daily with a weekday subset only hits those days', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        daysOfWeek: {DateTime.monday, DateTime.wednesday},
      );
      expect(r.matches(DateTime(2026, 9, 16), start), isTrue); // Wed
      expect(r.matches(DateTime(2026, 9, 17), start), isFalse); // Thu
      expect(r.matches(DateTime(2026, 9, 21), start), isTrue); // Mon
    });

    test('never matches before the start or after the end', () {
      final r = rule(
        frequency: RecurrenceFrequency.daily,
        endDate: DateTime(2026, 9, 20),
      );
      expect(r.matches(DateTime(2026, 9, 14), start), isFalse);
      expect(r.matches(DateTime(2026, 9, 20), start), isTrue); // inclusive
      expect(r.matches(DateTime(2026, 9, 21), start), isFalse);
    });
  });

  group('RecurrenceRule.matches — weekly', () {
    test('every 2 weeks flips at the week boundary, not per selected day',
        () {
      final r = rule(
        interval: 2,
        daysOfWeek: {DateTime.monday, DateTime.wednesday},
      );
      // Start week (Sun Sep 13 – Sat Sep 19) is week 0 — ON.
      expect(r.matches(DateTime(2026, 9, 16), start), isTrue); // Wed wk0
      // Week 1 is OFF for both days.
      expect(r.matches(DateTime(2026, 9, 21), start), isFalse); // Mon wk1
      expect(r.matches(DateTime(2026, 9, 23), start), isFalse); // Wed wk1
      // Week 2 is ON again.
      expect(r.matches(DateTime(2026, 9, 28), start), isTrue); // Mon wk2
      expect(r.matches(DateTime(2026, 9, 30), start), isTrue); // Wed wk2
    });

    test('empty weekday set falls back to the start weekday', () {
      final r = rule();
      expect(r.matches(DateTime(2026, 9, 22), start), isTrue); // Tue
      expect(r.matches(DateTime(2026, 9, 23), start), isFalse); // Wed
    });
  });

  group('RecurrenceRule.matches — monthly', () {
    test('day-of-month mode hits the same day each Nth month', () {
      final r = rule(frequency: RecurrenceFrequency.monthly, interval: 2);
      expect(r.matches(DateTime(2026, 11, 15), start), isTrue);
      expect(r.matches(DateTime(2026, 10, 15), start), isFalse); // off month
      expect(r.matches(DateTime(2026, 11, 14), start), isFalse);
    });

    test('nth-weekday mode follows the ordinal, not the date', () {
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        monthlyMode: MonthlyRepeatMode.nthWeekday,
      );
      // Third Tuesday of October 2026 is Oct 20.
      expect(r.matches(DateTime(2026, 10, 20), start), isTrue);
      expect(r.matches(DateTime(2026, 10, 13), start), isFalse); // 2nd Tue
      expect(r.matches(DateTime(2026, 10, 15), start), isFalse); // Thu
    });

    test('a start on the LAST weekday tracks the last occurrence', () {
      final lastTueStart = DateTime(2026, 9, 29);
      final r = rule(
        frequency: RecurrenceFrequency.monthly,
        monthlyMode: MonthlyRepeatMode.nthWeekday,
      );
      expect(r.matches(DateTime(2026, 10, 27), lastTueStart), isTrue);
      expect(r.matches(DateTime(2026, 11, 24), lastTueStart), isTrue);
      expect(r.matches(DateTime(2026, 10, 20), lastTueStart), isFalse);
    });
  });

  group('RecurrenceRule.matches — yearly', () {
    test('date mode hits the anniversary respecting the interval', () {
      final r = rule(
        frequency: RecurrenceFrequency.yearly,
        interval: 2,
        endDate: DateTime(2030, 12, 31),
      );
      expect(r.matches(DateTime(2028, 9, 15), start), isTrue);
      expect(r.matches(DateTime(2027, 9, 15), start), isFalse); // off year
      expect(r.matches(DateTime(2028, 9, 14), start), isFalse);
    });

    test('nth-weekday mode hits the same ordinal weekday of the month', () {
      final r = rule(
        frequency: RecurrenceFrequency.yearly,
        yearlyMode: YearlyRepeatMode.nthWeekday,
      );
      // Third Tuesday of September 2027 is Sep 21.
      expect(r.matches(DateTime(2027, 9, 21), start), isTrue);
      expect(r.matches(DateTime(2027, 9, 15), start), isFalse);
      expect(r.matches(DateTime(2027, 10, 19), start), isFalse); // wrong month
    });
  });

  group('RecurrenceRule.shiftStartWeekday', () {
    test('the start weekday follows the moved date', () {
      // Thu-only selection, event moves Thu → Fri.
      expect(
        RecurrenceRule.shiftStartWeekday(
          {DateTime.thursday},
          DateTime.thursday,
          DateTime.friday,
        ),
        {DateTime.friday},
      );
    });

    test('other manually picked days are preserved', () {
      expect(
        RecurrenceRule.shiftStartWeekday(
          {DateTime.monday, DateTime.thursday},
          DateTime.thursday,
          DateTime.friday,
        ),
        {DateTime.monday, DateTime.friday},
      );
    });

    test('no-op when the start weekday was not selected', () {
      expect(
        RecurrenceRule.shiftStartWeekday(
          {DateTime.monday},
          DateTime.thursday,
          DateTime.friday,
        ),
        {DateTime.monday},
      );
    });

    test('no duplicate when the new weekday was already selected', () {
      expect(
        RecurrenceRule.shiftStartWeekday(
          {DateTime.thursday, DateTime.friday},
          DateTime.thursday,
          DateTime.friday,
        ),
        {DateTime.friday},
      );
    });
  });

  group('RecurrenceEndPolicy', () {
    final start = DateTime(2026, 7, 14);

    test('defaults per frequency: +1m / +3m / +1y / +3y', () {
      expect(
        RecurrenceEndPolicy.defaultEnd(RecurrenceFrequency.daily, start),
        DateTime(2026, 8, 14),
      );
      expect(
        RecurrenceEndPolicy.defaultEnd(RecurrenceFrequency.weekly, start),
        DateTime(2026, 10, 14),
      );
      expect(
        RecurrenceEndPolicy.defaultEnd(RecurrenceFrequency.monthly, start),
        DateTime(2027, 7, 14),
      );
      expect(
        RecurrenceEndPolicy.defaultEnd(RecurrenceFrequency.yearly, start),
        DateTime(2029, 7, 14),
      );
    });

    test('maxima per frequency: +1y / +2y / +3y / +5y', () {
      expect(
        RecurrenceEndPolicy.maxEnd(RecurrenceFrequency.daily, start),
        DateTime(2027, 7, 14),
      );
      expect(
        RecurrenceEndPolicy.maxEnd(RecurrenceFrequency.weekly, start),
        DateTime(2028, 7, 14),
      );
      expect(
        RecurrenceEndPolicy.maxEnd(RecurrenceFrequency.monthly, start),
        DateTime(2029, 7, 14),
      );
      expect(
        RecurrenceEndPolicy.maxEnd(RecurrenceFrequency.yearly, start),
        DateTime(2031, 7, 14),
      );
    });

    test('clamp: null/before-start → default, beyond max → max, valid → kept',
        () {
      expect(
        RecurrenceEndPolicy.clamp(null, RecurrenceFrequency.weekly, start),
        DateTime(2026, 10, 14),
      );
      expect(
        RecurrenceEndPolicy.clamp(
          DateTime(2026, 1, 1),
          RecurrenceFrequency.weekly,
          start,
        ),
        DateTime(2026, 10, 14),
      );
      expect(
        RecurrenceEndPolicy.clamp(
          DateTime(2030, 1, 1),
          RecurrenceFrequency.weekly,
          start,
        ),
        DateTime(2028, 7, 14),
      );
      expect(
        RecurrenceEndPolicy.clamp(
          DateTime(2026, 12, 18),
          RecurrenceFrequency.weekly,
          start,
        ),
        DateTime(2026, 12, 18),
      );
    });
  });

  group('RecurrenceSummary', () {
    test('ordinal labels', () {
      expect(RecurrenceSummary.dayOfMonthLabel(DateTime(2026, 9, 1)), '1st');
      expect(RecurrenceSummary.dayOfMonthLabel(DateTime(2026, 9, 2)), '2nd');
      expect(RecurrenceSummary.dayOfMonthLabel(DateTime(2026, 9, 3)), '3rd');
      expect(RecurrenceSummary.dayOfMonthLabel(DateTime(2026, 9, 11)), '11th');
      expect(RecurrenceSummary.dayOfMonthLabel(DateTime(2026, 9, 21)), '21st');
      expect(
        RecurrenceSummary.nthWeekdayLabel(DateTime(2026, 9, 15)),
        'third Tuesday',
      );
      expect(
        RecurrenceSummary.nthWeekdayLabel(DateTime(2026, 9, 29)),
        'last Tuesday',
      );
    });

    test('compact labels', () {
      expect(RecurrenceSummary.compact(rule()), 'Weekly');
      expect(RecurrenceSummary.compact(rule(interval: 2)), 'Every other week');
      expect(
        RecurrenceSummary.compact(
          rule(frequency: RecurrenceFrequency.monthly, interval: 3),
        ),
        'Every 3 months',
      );
    });

    test('full summary matches the web grammar', () {
      expect(
        RecurrenceSummary.describe(
          rule: rule(
            interval: 2,
            daysOfWeek: {DateTime.monday, DateTime.wednesday},
            endDate: DateTime(2026, 12, 18),
          ),
          startDate: start,
          startTime: '13:00',
          endTime: '13:30',
        ),
        'Occurs every other week on Mon, Wed, 13:00 – 13:30, '
        'until Dec 18, 2026',
      );
    });

    test('every day with all days selected needs no "on" clause', () {
      expect(
        RecurrenceSummary.describe(
          rule: rule(
            frequency: RecurrenceFrequency.daily,
            daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
            endDate: DateTime(2026, 12, 18),
          ),
          startDate: start,
        ),
        'Occurs every day, until Dec 18, 2026',
      );
    });

    test('monthly and yearly summaries anchor on the start date', () {
      expect(
        RecurrenceSummary.describe(
          rule: rule(
            frequency: RecurrenceFrequency.monthly,
            monthlyMode: MonthlyRepeatMode.nthWeekday,
            endDate: DateTime(2027, 9, 15),
          ),
          startDate: start,
        ),
        'Occurs every month on the third Tuesday, until Sep 15, 2027',
      );
      expect(
        RecurrenceSummary.describe(
          rule: rule(
            frequency: RecurrenceFrequency.yearly,
            endDate: DateTime(2030, 9, 15),
          ),
          startDate: start,
        ),
        'Occurs every year on Sep 15, until Sep 15, 2030',
      );
    });
  });
}
