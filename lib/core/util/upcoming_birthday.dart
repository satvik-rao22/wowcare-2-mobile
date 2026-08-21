import 'package:wowcare/core/util/app_time.dart';

/// Computes how many days remain until a student's next birthday, so cards
/// can surface a small heads-up (matching the web app's "In N days" badge)
/// without needing the actual current age.
class UpcomingBirthday {
  const UpcomingBirthday._();

  /// Birthdays further out than this are not surfaced on cards.
  static const int maxDays = 3;

  /// Returns 0-[maxDays] (0 = today) for the next occurrence of the
  /// month/day encoded in [dob], or null if [dob] is missing/unparseable or
  /// the birthday is further away than [maxDays].
  static int? daysUntil(String? dob, {DateTime? now}) {
    final trimmed = dob?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;

    final today = _dateOnly(now ?? AppTime.now());
    var next = _safeDate(today.year, parsed.month, parsed.day);
    if (next.isBefore(today)) {
      next = _safeDate(today.year + 1, parsed.month, parsed.day);
    }

    final diff = next.difference(today).inDays;
    return diff <= maxDays ? diff : null;
  }

  static String label(int daysUntil) {
    switch (daysUntil) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      default:
        return 'In $daysUntil days';
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Guards against Feb 29 in a non-leap [year] by clamping to the last day
  /// of the month instead.
  static DateTime _safeDate(int year, int month, int day) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > daysInMonth ? daysInMonth : day);
  }
}
