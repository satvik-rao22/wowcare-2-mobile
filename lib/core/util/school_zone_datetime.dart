import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// Interprets attendance date/times in the **school's** IANA zone so behavior matches
/// backend rules (e.g. school hours) when the device is in another country.
///
/// Requires [initializeTimeZones] from `timezone/data/latest.dart` in [main].
abstract final class SchoolZoneDateTime {
  SchoolZoneDateTime._();

  static tz.Location locationForIana(String ianaName) {
    final id = ianaName.trim().isEmpty ? 'UTC' : ianaName.trim();
    try {
      return tz.getLocation(id);
    } catch (_) {
      return tz.UTC;
    }
  }

  /// "Now" in the school zone — use for non-admin flows (exact instant).
  static DateTime utcNowInSchool(String ianaName) {
    final loc = locationForIana(ianaName);
    return tz.TZDateTime.now(loc).toUtc();
  }

  /// Interprets [year]/[month]/[day] + [hour]/[minute] as **school wall clock** and returns UTC.
  static DateTime utcFromSchoolWallClock(
    String ianaName, {
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    final loc = locationForIana(ianaName);
    return tz.TZDateTime(loc, year, month, day, hour, minute).toUtc();
  }

  /// Interprets [wallClock]'s calendar + clock fields as **school wall clock**
  /// and returns the corresponding UTC instant.
  ///
  /// Use for a date/time the user PICKED (a calendar concept), never for an
  /// instant. `picked.toUtc()` is wrong for picked values: it reads the fields
  /// in the DEVICE's zone, so `DateTime(2026, 7, 17)` on an IST device becomes
  /// `2026-07-16T18:30:00Z` — a day earlier than the user chose.
  static DateTime utcFromSchoolWallClockDateTime(
    DateTime wallClock,
    String ianaName,
  ) {
    final loc = locationForIana(ianaName);
    return tz.TZDateTime(
      loc,
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
    ).toUtc();
  }

  /// Calendar date (yyyy-MM-dd) of [utcInstant] as seen in the school zone.
  static String yyyyMmDdFromUtcInstant(DateTime utcInstant, String ianaName) {
    final loc = locationForIana(ianaName);
    final t = tz.TZDateTime.from(utcInstant.toUtc(), loc);
    return '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}';
  }

  /// Time-of-day of [instant] as seen in the school zone.
  static TimeOfDay timeOfDayFromInstantInSchool(
    DateTime instant,
    String ianaName,
  ) {
    final loc = locationForIana(ianaName);
    final t = tz.TZDateTime.from(instant.toUtc(), loc);
    return TimeOfDay(hour: t.hour, minute: t.minute);
  }

  /// DateTime of [instant] as seen in the school zone.
  /// Returned as a regular [DateTime] with the school-zone calendar/clock fields.
  static DateTime dateTimeFromInstantInSchool(
    DateTime instant,
    String ianaName,
  ) {
    final loc = locationForIana(ianaName);
    final t = tz.TZDateTime.from(instant.toUtc(), loc);
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }

  /// Date-only "today" in the school calendar (for comparing picked dates).
  static DateTime schoolCalendarTodayOnly(String ianaName) {
    final n = tz.TZDateTime.now(locationForIana(ianaName));
    return DateTime(n.year, n.month, n.day);
  }

  /// Current school calendar date + time-of-day for pickers / defaults.
  static (DateTime dateOnly, TimeOfDay timeOfDay) schoolCalendarDateAndTimeNow(
    String ianaName,
  ) {
    final sn = tz.TZDateTime.now(locationForIana(ianaName));
    return (
      DateTime(sn.year, sn.month, sn.day),
      TimeOfDay(hour: sn.hour, minute: sn.minute),
    );
  }
}
