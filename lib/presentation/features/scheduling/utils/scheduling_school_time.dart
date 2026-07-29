import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

/// Resolves and caches the current school's IANA timezone for scheduling
/// screens. Call once from a screen's `initState` (the resolver caches the
/// result, so repeated calls across screens are cheap).
Future<String> bootstrapSchedulingSchoolTimezone() {
  return SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
}

/// School-calendar "today" using the most recently resolved zone. Falls back
/// to device-local today when no school zone has been resolved yet, so it is
/// safe to call synchronously before [bootstrapSchedulingSchoolTimezone]
/// settles.
DateTime schedulingSchoolToday() {
  final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
  if (tz.isEmpty ||
      tz.toUpperCase() ==
          SchoolTimezoneResolver.fallbackTimeZone.toUpperCase()) {
    final n = AppTime.now();
    return DateTime(n.year, n.month, n.day);
  }
  return SchoolZoneDateTime.schoolCalendarTodayOnly(tz);
}

/// Renders a UTC ISO timestamp from the API as a school-zone wall-clock
/// [DateTime] for display.
DateTime schedulingDateTimeForDisplayFromIso(String iso) {
  final parsed = DateTime.parse(iso);
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    parsed,
    SchoolTimezoneResolver.lastKnownTimeZone,
  );
}

/// Converts a date + time-of-day picked in the school's wall clock into the
/// corresponding UTC ISO instant for submission.
Future<String> schedulingUtcIsoFromSchoolWallClock({
  required DateTime date,
  required TimeOfDay time,
}) async {
  final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
  return SchoolZoneDateTime.utcFromSchoolWallClock(
    schoolTimeZone,
    year: date.year,
    month: date.month,
    day: date.day,
    hour: time.hour,
    minute: time.minute,
  ).toIso8601String();
}
