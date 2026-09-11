import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

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

  /// "Now" as a UTC instant, sourced from the server clock (see
  /// [ServerTimeService]) rather than the raw device clock. The zone argument is
  /// irrelevant to a UTC instant and kept only for call-site compatibility.
  static DateTime utcNowInSchool(String ianaName) {
    return ServerTimeService.instance.nowUtc();
  }

  /// Server-clock "now" as a [tz.TZDateTime] in [loc] — the single place the
  /// class turns the corrected instant into wall-clock fields.
  static tz.TZDateTime _nowInZone(tz.Location loc) {
    return tz.TZDateTime.from(ServerTimeService.instance.nowUtc(), loc);
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
    final n = _nowInZone(locationForIana(ianaName));
    return DateTime(n.year, n.month, n.day);
  }

  /// Current school calendar date + time-of-day for pickers / defaults.
  static (DateTime dateOnly, TimeOfDay timeOfDay) schoolCalendarDateAndTimeNow(
    String ianaName,
  ) {
    final sn = _nowInZone(locationForIana(ianaName));
    return (
      DateTime(sn.year, sn.month, sn.day),
      TimeOfDay(hour: sn.hour, minute: sn.minute),
    );
  }

  /// Resolves the UTC instant to submit for a date/time PICKER field.
  ///
  /// If [selectedDate]/[selectedTime] still equal the current school wall
  /// clock (the picker's untouched default), returns the real synced server
  /// instant — full second precision, not truncated to hh:mm:00. If the user
  /// explicitly picked a different date/time, honors that picked value
  /// instead (seconds are 0 — a [TimeOfDay] picker has no seconds to give).
  ///
  /// Use this instead of calling [utcFromSchoolWallClock] directly wherever a
  /// picker's value becomes a submitted "occurred at" timestamp (sign-in/out,
  /// transfer, activity time, etc.).
  static DateTime resolvePickedInstantUtc(
    String ianaName, {
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
  }) {
    final schoolNow = _nowInZone(locationForIana(ianaName));
    final isUnchanged =
        selectedDate.year == schoolNow.year &&
        selectedDate.month == schoolNow.month &&
        selectedDate.day == schoolNow.day &&
        selectedTime.hour == schoolNow.hour &&
        selectedTime.minute == schoolNow.minute;
    AppLogger.d(
      '[resolvePickedInstantUtc] iana=$ianaName '
      'picked=${selectedDate.year}-${selectedDate.month}-${selectedDate.day} '
      '${selectedTime.hour}:${selectedTime.minute} '
      'schoolNow=${schoolNow.year}-${schoolNow.month}-${schoolNow.day} '
      '${schoolNow.hour}:${schoolNow.minute} '
      'isUnchanged=$isUnchanged',
    );
    if (isUnchanged) return ServerTimeService.instance.nowUtc();

    return utcFromSchoolWallClock(
      ianaName,
      year: selectedDate.year,
      month: selectedDate.month,
      day: selectedDate.day,
      hour: selectedTime.hour,
      minute: selectedTime.minute,
    );
  }
}
