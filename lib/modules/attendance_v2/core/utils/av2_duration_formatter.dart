/// Formats minute counts into compact human labels used across the module.
///
/// All attendance math arrives as integer minutes from the backend; the UI
/// only ever formats — never computes payroll values.
class Av2DurationFormatter {
  const Av2DurationFormatter._();

  /// 496 -> "8h 16m", 45 -> "45m", 480 -> "8h", 0 -> "0m".
  static String hm(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Short form for chips: 16 -> "+16m", 85 -> "+1h 25m". Empty when zero.
  static String overtimeChip(int minutes) {
    if (minutes <= 0) return '';
    return '+${hm(minutes)}';
  }

  /// Hours-only rounded label for legends: 3840 -> "64h".
  static String hoursLabel(int minutes) {
    final h = (minutes / 60).round();
    return '${h}h';
  }
}
