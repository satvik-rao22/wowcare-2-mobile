import 'package:wowcare/core/utils/billing_school_time.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';

/// Date-only start/end pair for a billing date-range filter.
typedef BillingDateBounds = ({DateTime start, DateTime end});

/// Quick-select presets for the accounting / transactions date-range filter.
///
/// Every preset is the **whole** calendar period containing school "today"
/// (so "This week" runs Sunday through Saturday even if today is Wednesday).
/// That matches the existing default, which is the whole current month, and
/// keeps the stat-bar totals comparable period over period.
enum BillingQuickRange {
  thisYear,
  thisMonth,
  thisWeek;

  /// User-visible label, also used as the dropdown item text.
  String get label {
    switch (this) {
      case BillingQuickRange.thisYear:
        return BillingStrings.thisYear;
      case BillingQuickRange.thisMonth:
        return BillingStrings.thisMonth;
      case BillingQuickRange.thisWeek:
        return BillingStrings.thisWeek;
    }
  }

  /// Dropdown items in display order.
  static List<String> get labels =>
      BillingQuickRange.values.map((r) => r.label).toList(growable: false);

  /// Reverse lookup from a dropdown item text; null for an unknown label.
  static BillingQuickRange? fromLabel(String? label) {
    for (final r in BillingQuickRange.values) {
      if (r.label == label) return r;
    }
    return null;
  }

  /// Date-only bounds of this period for the calendar day [today]. Weeks are
  /// Sunday-first, matching the [CalendarDialog] grid this preset sits next
  /// to, so "This week" highlights exactly one row of that picker.
  BillingDateBounds boundsFor(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    switch (this) {
      case BillingQuickRange.thisYear:
        return (start: DateTime(t.year, 1, 1), end: DateTime(t.year, 12, 31));
      case BillingQuickRange.thisMonth:
        return (
          start: DateTime(t.year, t.month, 1),
          // Day 0 of next month rolls back to the last day of this one.
          end: DateTime(t.year, t.month + 1, 0),
        );
      case BillingQuickRange.thisWeek:
        // DateTime.sunday is 7, so `% 7` maps Sunday to a zero offset.
        final start = t.subtract(Duration(days: t.weekday % 7));
        return (start: start, end: start.add(const Duration(days: 6)));
    }
  }

  /// Bounds for the current school-calendar day.
  BillingDateBounds get bounds => boundsFor(billingSchoolToday());

  /// True when [start]..[end] is exactly this preset's period for [today],
  /// comparing calendar days only (pickers may carry a 23:59:59 end time).
  bool matches(DateTime? start, DateTime? end, {DateTime? today}) {
    if (start == null || end == null) return false;
    final b = boundsFor(today ?? billingSchoolToday());
    return _sameDay(b.start, start) && _sameDay(b.end, end);
  }

  /// The preset whose period is exactly [start]..[end], if any.
  static BillingQuickRange? matching(
    DateTime? start,
    DateTime? end, {
    DateTime? today,
  }) {
    for (final r in BillingQuickRange.values) {
      if (r.matches(start, end, today: today)) return r;
    }
    return null;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
