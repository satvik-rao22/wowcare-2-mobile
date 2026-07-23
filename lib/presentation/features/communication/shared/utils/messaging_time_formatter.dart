import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

/// Single source of truth for all messaging timestamp formatting.
///
/// All methods convert [DateTime] values to the school's IANA timezone
/// (via [SchoolTimezoneResolver]) and produce a consistent 12-hour AM/PM
/// display string.  Callers must never roll their own time formatting.
abstract final class MessagingTimeFormatter {
  MessagingTimeFormatter._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Formats a message-bubble timestamp.
  ///
  /// • < 30 s old → "Now"
  /// • Otherwise  → "h:mm AM/PM" in the school's timezone
  static String bubbleTime(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inSeconds < 30) return 'Now';
    final local = _toSchool(dt);
    return _format12h(local);
  }

  /// Formats a conversation-list / inbox timestamp.
  ///
  /// • Today     → "Today | h:mm AM/PM"
  /// • Yesterday → "Yesterday | h:mm AM/PM"
  /// • < 7 days  → "Mon | h:mm AM/PM"
  /// • Older     → "DD Mon YYYY"
  static String conversationTime(DateTime? dt) {
    if (dt == null) return '—';
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final local = _toSchool(dt);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      AppTime.now().toUtc(),
      schoolTz,
    );
    final diff = _daysDiff(now, local);
    final timeStr = _format12h(local);

    if (diff == 0) return 'Today | $timeStr';
    if (diff == 1) return 'Yesterday | $timeStr';
    if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[local.weekday - 1]} | $timeStr';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  /// Formats a timestamp for message-info / read-receipt panels.
  ///
  /// Returns "Today, h:mm AM/PM", "Yesterday, h:mm AM/PM", or
  /// "DD Mon YYYY, h:mm AM/PM".
  static String infoTime(DateTime dt) {
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final local = _toSchool(dt);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      AppTime.now().toUtc(),
      schoolTz,
    );
    final diff = _daysDiff(now, local);
    final timeStr = _format12h(local);

    if (diff == 0) return 'Today, $timeStr';
    if (diff == 1) return 'Yesterday, $timeStr';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}, $timeStr';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static DateTime _toSchool(DateTime dt) =>
      SchoolZoneDateTime.dateTimeFromInstantInSchool(
        dt.toUtc(),
        SchoolTimezoneResolver.lastKnownTimeZone,
      );

  /// Returns a "h:mm AM/PM" string (no leading zero on the hour).
  static String _format12h(DateTime dt) {
    final hour = dt.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  /// Whole-day difference between two school-zone [DateTime]s.
  static int _daysDiff(DateTime now, DateTime msg) {
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(msg.year, msg.month, msg.day);
    return today.difference(msgDay).inDays;
  }
}
