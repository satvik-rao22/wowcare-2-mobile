import 'package:intl/intl.dart';
import 'package:wowcare/redesign/features/notifications/models/notification_group.dart';
import 'package:wowcare/redesign/features/notifications/notifications_strings.dart';

/// How a notification's timestamp is written, and which day band it falls in.
///
/// Both take the school's clock as [now] rather than reading the device's.
/// Time in this app is school-timezone based, so the page carries the moment
/// its fetch was answered and every row is measured against that one value:
/// the whole list ages together instead of each row drifting on its own.
abstract final class NotificationsFormats {
  /// Anything older than this is written as a date rather than a count.
  static const int _daysBeforeDate = 7;

  static final DateFormat _date = DateFormat('d MMM');

  /// "4 mins ago", "1 hr ago", "1 day ago", then "15 Aug".
  static String relativeTime(DateTime at, DateTime now) {
    final elapsed = now.difference(at);
    if (elapsed.inMinutes < 1) return NotificationsStrings.justNow;
    if (elapsed.inMinutes < Duration.minutesPerHour) {
      return NotificationsStrings.minsAgo(elapsed.inMinutes);
    }
    if (elapsed.inHours < Duration.hoursPerDay) {
      return NotificationsStrings.hoursAgo(elapsed.inHours);
    }
    if (elapsed.inDays < _daysBeforeDate) {
      return NotificationsStrings.daysAgo(elapsed.inDays);
    }
    return _date.format(at);
  }

  /// Which band a row sits under. Calendar days, not elapsed hours: something
  /// at 11pm last night is Yesterday at 8am, whatever the clock says.
  static NotificationDay dayOf(DateTime at, DateTime now) {
    final days = _midnight(now).difference(_midnight(at)).inDays;
    if (days <= 0) return NotificationDay.today;
    if (days == 1) return NotificationDay.yesterday;
    return NotificationDay.earlier;
  }

  /// The band's label.
  static String dayLabel(NotificationDay day) => switch (day) {
    NotificationDay.today => NotificationsStrings.today,
    NotificationDay.yesterday => NotificationsStrings.yesterday,
    NotificationDay.earlier => NotificationsStrings.earlier,
  };

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
}
