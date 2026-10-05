import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/billing/model/billing_quick_range.dart';

void main() {
  group('BillingQuickRange.boundsFor', () {
    // Wednesday 2026-09-16.
    final wednesday = DateTime(2026, 9, 16, 13, 45);

    test('this year is Jan 1 .. Dec 31 of the calendar year', () {
      final b = BillingQuickRange.thisYear.boundsFor(wednesday);
      expect(b.start, DateTime(2026, 1, 1));
      expect(b.end, DateTime(2026, 12, 31));
    });

    test('this month is the first .. last day of the month', () {
      final b = BillingQuickRange.thisMonth.boundsFor(wednesday);
      expect(b.start, DateTime(2026, 9, 1));
      expect(b.end, DateTime(2026, 9, 30));
    });

    test('this month handles February in a leap year', () {
      final b = BillingQuickRange.thisMonth.boundsFor(DateTime(2028, 2, 10));
      expect(b.end, DateTime(2028, 2, 29));
    });

    test('this week is Sunday .. Saturday around a midweek day', () {
      final b = BillingQuickRange.thisWeek.boundsFor(wednesday);
      expect(b.start, DateTime(2026, 9, 13));
      expect(b.end, DateTime(2026, 9, 19));
    });

    test('this week on a Sunday starts today', () {
      final b = BillingQuickRange.thisWeek.boundsFor(DateTime(2026, 9, 13));
      expect(b.start, DateTime(2026, 9, 13));
      expect(b.end, DateTime(2026, 9, 19));
    });

    test('this week on a Saturday ends today', () {
      final b = BillingQuickRange.thisWeek.boundsFor(DateTime(2026, 9, 19));
      expect(b.start, DateTime(2026, 9, 13));
      expect(b.end, DateTime(2026, 9, 19));
    });

    test('this week on a Monday started yesterday', () {
      final b = BillingQuickRange.thisWeek.boundsFor(DateTime(2026, 9, 14));
      expect(b.start, DateTime(2026, 9, 13));
      expect(b.end, DateTime(2026, 9, 19));
    });

    test('this week crosses a month boundary', () {
      // Wednesday 2026-09-30 -> Sun Sep 27 .. Sat Oct 3.
      final b = BillingQuickRange.thisWeek.boundsFor(DateTime(2026, 9, 30));
      expect(b.start, DateTime(2026, 9, 27));
      expect(b.end, DateTime(2026, 10, 3));
    });

    test('bounds are date-only even when today carries a time', () {
      final b = BillingQuickRange.thisWeek.boundsFor(wednesday);
      expect(b.start.hour, 0);
      expect(b.end.hour, 0);
    });
  });

  group('BillingQuickRange.matches / matching', () {
    final today = DateTime(2026, 9, 16);

    test('exact month bounds match This month', () {
      expect(
        BillingQuickRange.matching(
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 30),
          today: today,
        ),
        BillingQuickRange.thisMonth,
      );
    });

    test('ignores a 23:59:59 end time from the calendar dialog', () {
      expect(
        BillingQuickRange.thisMonth.matches(
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 30, 23, 59, 59),
          today: today,
        ),
        isTrue,
      );
    });

    test('a custom range matches nothing', () {
      expect(
        BillingQuickRange.matching(
          DateTime(2026, 9, 3),
          DateTime(2026, 9, 30),
          today: today,
        ),
        isNull,
      );
    });

    test('null dates match nothing', () {
      expect(BillingQuickRange.matching(null, null, today: today), isNull);
    });
  });

  group('labels', () {
    test('round-trip through fromLabel', () {
      for (final r in BillingQuickRange.values) {
        expect(BillingQuickRange.fromLabel(r.label), r);
      }
      expect(BillingQuickRange.fromLabel('Nope'), isNull);
      expect(BillingQuickRange.fromLabel(null), isNull);
    });

    test('dropdown order is year, month, week', () {
      expect(BillingQuickRange.labels, [
        'This year',
        'This month',
        'This week',
      ]);
    });
  });
}
