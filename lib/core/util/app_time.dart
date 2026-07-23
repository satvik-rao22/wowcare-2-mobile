import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';

/// App-wide "now" for USER-FACING calendar values — a drop-in for
/// `DateTime.now()` that returns the authoritative **server** clock rendered in
/// the **school** timezone (never the device clock or device zone).
///
/// Use this for anything a user sees or that scopes a calendar day: date-field
/// defaults, "today" for a data load, month/range boundaries, display defaults.
///
/// Do NOT use it for elapsed-time logic — cache freshness, debounce/throttle
/// windows, retry backoff, animation timing. Those measure real elapsed
/// duration and must stay on the raw device clock (`DateTime.now()`); routing
/// them through a network-synced clock would add a pointless dependency and can
/// skew short intervals by the sync offset.
abstract final class AppTime {
  AppTime._();

  /// Server-corrected UTC instant.
  static DateTime nowUtc() => ServerTimeService.instance.nowUtc();

  /// Server-corrected "now" as a plain [DateTime] carrying the SCHOOL zone's
  /// wall-clock fields. Drop-in replacement for `DateTime.now()`.
  static DateTime now() => SchoolZoneDateTime.dateTimeFromInstantInSchool(
        ServerTimeService.instance.nowUtc(),
        SchoolTimezoneResolver.lastKnownTimeZone,
      );

  /// Date-only "today" in the school calendar (drop-in for
  /// `DateTime(DateTime.now().year, month, day)`).
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}
