import 'package:flutter/material.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

/// School-timezone helpers for the attendance module.
///
/// Every attendance screen must interpret dates/times in the **school's** IANA
/// zone (not the device zone) so "today", date-range query params, picker
/// defaults and displayed times all match the backend — exactly as the activity
/// and scheduling modules do. Timestamps sent to the API stay UTC; the school
/// zone only decides which calendar day / wall-clock a value maps to.
///
/// Sync helpers use [SchoolTimezoneResolver.lastKnownTimeZone] (resolved once on
/// screen entry via [bootstrapAttendanceSchoolTimezone]) and fall back to device
/// time when the zone is still the [SchoolTimezoneResolver.fallbackTimeZone].

/// Resolves and caches the current school timezone. Call once on attendance
/// screen entry (e.g. in `initState`) before reading the sync helpers, and
/// `setState`/`emit` afterwards so the first frame's device-time fallback is
/// replaced with school time.
Future<String> bootstrapAttendanceSchoolTimezone() {
  return SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
}

/// The last resolved school IANA zone (or the `UTC` fallback).
String attendanceSchoolIana() => SchoolTimezoneResolver.lastKnownTimeZone;

bool _isUsableZone(String iana) {
  final tz = iana.trim();
  return tz.isNotEmpty &&
      tz.toUpperCase() != SchoolTimezoneResolver.fallbackTimeZone.toUpperCase();
}

/// Date-only "today" in the school calendar (device-today fallback). Use to seed
/// a screen's selected date and to validate picked dates.
DateTime attendanceSchoolToday() {
  final iana = attendanceSchoolIana();
  if (!_isUsableZone(iana)) {
    final n = ServerTimeService.instance.now();
    return DateTime(n.year, n.month, n.day);
  }
  return SchoolZoneDateTime.schoolCalendarTodayOnly(iana);
}

/// Current school calendar date + time-of-day (device-now fallback). Use as
/// date/time picker defaults.
(DateTime dateOnly, TimeOfDay timeOfDay) attendanceSchoolDateAndTimeNow() {
  final iana = attendanceSchoolIana();
  if (!_isUsableZone(iana)) {
    final n = ServerTimeService.instance.now();
    return (DateTime(n.year, n.month, n.day), TimeOfDay(hour: n.hour, minute: n.minute));
  }
  return SchoolZoneDateTime.schoolCalendarDateAndTimeNow(iana);
}

/// Formats a date-only value (already a school-calendar date) as `yyyy-MM-dd`
/// for date query params — no zone conversion, just the components.
String attendanceYyyyMmDd(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Parses an API ISO instant and returns it as a [DateTime] with the school
/// zone's calendar/clock fields, for display. Returns null if unparseable.
DateTime? attendanceDisplayDateTimeFromIso(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso.trim());
  if (parsed == null) return null;
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    parsed,
    attendanceSchoolIana(),
  );
}

/// Time-of-day of an API ISO instant as seen in the school zone, for display.
TimeOfDay? attendanceDisplayTimeOfDayFromIso(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso.trim());
  if (parsed == null) return null;
  return SchoolZoneDateTime.timeOfDayFromInstantInSchool(
    parsed,
    attendanceSchoolIana(),
  );
}

/// Converts a user-picked school wall-clock date + time to a UTC ISO string for
/// API submission (resolves the zone freshly to be safe).
Future<String> attendanceUtcIsoFromSchoolWallClock({
  required DateTime date,
  required TimeOfDay time,
}) async {
  final schoolTimeZone = await bootstrapAttendanceSchoolTimezone();
  return SchoolZoneDateTime.resolvePickedInstantUtc(
    schoolTimeZone,
    selectedDate: date,
    selectedTime: time,
  ).toIso8601String();
}
