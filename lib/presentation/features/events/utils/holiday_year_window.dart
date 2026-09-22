/// The span of years the Holiday List can show: the current year ±2
/// (FR-HL-07/08).
///
/// Shared by the year dropdown and by holiday notification deep links — a
/// notification may name any year, but selecting one outside this window would
/// leave the list showing that year while the dropdown (which falls back to the
/// current year for values it has no item for) shows another. Deep links check
/// [contains] first and simply keep the current year when the payload's year is
/// out of range.
class HolidayYearWindow {
  HolidayYearWindow._();

  /// Years either side of the current one that the selector offers.
  static const int radius = 2;

  /// The selectable years, ascending. [now] is injectable for tests.
  static List<int> options([DateTime? now]) {
    final current = (now ?? DateTime.now()).year;
    return [for (var y = current - radius; y <= current + radius; y++) y];
  }

  static bool contains(int year, [DateTime? now]) =>
      options(now).contains(year);

  /// First selectable day — 1 January of the earliest offered year.
  ///
  /// Holidays are only ever listed through the year selector, so one created
  /// outside this window is invisible in the app the moment it is saved. The
  /// API accepts any year (a 2035 holiday was accepted on DEV), so the window
  /// is enforced here, on both the picker's bounds and the typed date.
  static DateTime firstDate([DateTime? now]) => DateTime(options(now).first);

  /// Last selectable day — 31 December of the latest offered year.
  static DateTime lastDate([DateTime? now]) =>
      DateTime(options(now).last, 12, 31);

  /// Human-readable range for validation messages, e.g. "2024–2028".
  static String label([DateTime? now]) {
    final years = options(now);
    return '${years.first}–${years.last}';
  }
}
