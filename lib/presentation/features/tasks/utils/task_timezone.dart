import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';

/// Resolves the school's IANA timezone for the Tasks module and converts
/// between the wire's UTC date/time fields and the school-local wall clock
/// shown in every Tasks date/time picker and read-only view.
///
/// Wraps the shared [SchoolTimezoneResolver] but swaps its bare `UTC`
/// fallback (used app-wide when no school timezone has been resolved yet)
/// for Boston (`America/New_York`) — Tasks always wants a concrete local
/// frame for its pickers, and Boston is the primary school today. This only
/// affects Tasks; attendance/scheduling/geofencing keep the shared `UTC`
/// fallback untouched.
abstract final class TaskTimezone {
  TaskTimezone._();

  static const String fallbackTimeZone = 'America/New_York';

  static String _substituteFallback(String resolved) =>
      resolved.trim().toUpperCase() ==
              SchoolTimezoneResolver.fallbackTimeZone.toUpperCase()
          ? fallbackTimeZone
          : resolved;

  /// Best-known timezone without waiting on network/storage — for seeding a
  /// widget's first frame before [resolve] completes.
  static String get lastKnownTimeZone =>
      _substituteFallback(SchoolTimezoneResolver.lastKnownTimeZone);

  /// Resolves (fetching/caching as needed) the current school's timezone,
  /// falling back to [fallbackTimeZone] instead of the shared resolver's
  /// bare `UTC` when no school timezone is known.
  static Future<String> resolve() async {
    try {
      final resolved = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: serviceLocator<StorageService>(),
        apiClient: serviceLocator<ApiClient>(),
      );
      return _substituteFallback(resolved);
    } catch (_) {
      return fallbackTimeZone;
    }
  }

  /// "Today" in the school zone (date-only) — for a new task's default
  /// start/due date and every picker's lower/upper bounds.
  static DateTime today(String ianaName) =>
      SchoolZoneDateTime.schoolCalendarTodayOnly(ianaName);

  /// Converts a school-local wall-clock date + time (as picked in the form)
  /// into the UTC date + `HH:mm` the Tasks API wire format expects. The
  /// UTC date can land on the day before/after [date] when the school's
  /// offset pushes the instant across midnight.
  static (DateTime utcDate, String utcHhmm) toUtcWire({
    required DateTime date,
    required TimeOfDay time,
    required String ianaName,
  }) {
    final instant = SchoolZoneDateTime.utcFromSchoolWallClock(
      ianaName,
      year: date.year,
      month: date.month,
      day: date.day,
      hour: time.hour,
      minute: time.minute,
    );
    final utcDate = DateTime.utc(instant.year, instant.month, instant.day);
    final hhmm = '${instant.hour.toString().padLeft(2, '0')}:'
        '${instant.minute.toString().padLeft(2, '0')}';
    return (utcDate, hhmm);
  }

  /// Converts the wire's UTC date + `HH:mm` back into the school-local
  /// wall-clock date + time-of-day shown in pickers and read-only views.
  static (DateTime date, TimeOfDay time) fromUtcWire({
    required DateTime utcDate,
    required String hhmm,
    required String ianaName,
  }) {
    final parts = hhmm.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    final instant =
        DateTime.utc(utcDate.year, utcDate.month, utcDate.day, hour, minute);
    final local =
        SchoolZoneDateTime.dateTimeFromInstantInSchool(instant, ianaName);
    return (
      DateTime(local.year, local.month, local.day),
      TimeOfDay(hour: local.hour, minute: local.minute),
    );
  }
}
