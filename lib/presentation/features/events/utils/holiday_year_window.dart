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
}
