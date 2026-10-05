import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/billing/model/billing_quick_range.dart';
import 'package:wowcare/presentation/features/billing/view_model/date_range_cubit.dart';

void main() {
  group('DateRangeCubit', () {
    test('setRange without a preset clears the preset', () {
      final cubit = DateRangeCubit(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
        preset: BillingQuickRange.thisMonth,
      );
      cubit.setRange(DateTime(2026, 9, 3), DateTime(2026, 9, 10));
      expect(cubit.state.preset, isNull);
      expect(cubit.state.startDate, DateTime(2026, 9, 3));
      cubit.close();
    });

    test('applyPreset stores the preset and its bounds', () {
      final cubit = DateRangeCubit();
      cubit.applyPreset(BillingQuickRange.thisYear);
      final b = BillingQuickRange.thisYear.bounds;
      expect(cubit.state.preset, BillingQuickRange.thisYear);
      expect(cubit.state.startDate, b.start);
      expect(cubit.state.endDate, b.end);
      cubit.close();
    });

    test('syncExternal with identical dates is a no-op', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 30);
      final cubit = DateRangeCubit(
        start: start,
        end: end,
        preset: BillingQuickRange.thisMonth,
      );
      final before = cubit.state;
      cubit.syncExternal(start, end);
      expect(cubit.state, same(before));
      cubit.close();
    });

    test('syncExternal keeps the preset while the dates still match it', () {
      final cubit = DateRangeCubit();
      cubit.applyPreset(BillingQuickRange.thisMonth);
      final b = BillingQuickRange.thisMonth.bounds;
      // Owner echoes the same calendar days back as new instances.
      cubit.syncExternal(
        DateTime(b.start.year, b.start.month, b.start.day),
        DateTime(b.end.year, b.end.month, b.end.day, 23, 59, 59),
      );
      expect(cubit.state.preset, BillingQuickRange.thisMonth);
      cubit.close();
    });

    test('syncExternal drops the preset when the dates no longer match', () {
      final cubit = DateRangeCubit();
      cubit.applyPreset(BillingQuickRange.thisMonth);
      cubit.syncExternal(DateTime(2020, 1, 1), DateTime(2020, 1, 15));
      expect(cubit.state.preset, isNull);
      expect(cubit.state.startDate, DateTime(2020, 1, 1));
      cubit.close();
    });
  });
}
