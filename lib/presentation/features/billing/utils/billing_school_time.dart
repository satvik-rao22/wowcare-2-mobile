import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';

/// School-timezone helpers for the billing module.
///
/// Billing dates (invoice issue/due dates, statement periods, ledger date-range
/// filters, analytics years) are all **school-calendar** concepts: an invoice
/// raised "today" means today at the school, not on the device. A device in a
/// different zone would otherwise pick the wrong day near midnight — issuing an
/// invoice dated tomorrow, or filtering a range that silently drops a day.
///
/// Mirrors the per-module helpers used elsewhere
/// (`scheduling_school_time.dart`, `activity_school_time.dart`,
/// `attendance_school_time.dart`).
///
/// Note the shared pickers ([CustomDateTimeField], [CalendarDialog]) already
/// resolve the school zone for their own defaults — these helpers cover the
/// dates billing builds itself (range resets, "today" fallbacks, payload
/// timestamps).

/// Resolves and caches the current school's IANA timezone for billing screens.
/// Call once from a screen's `initState` / cubit load (the resolver caches, so
/// repeated calls across screens are cheap).
Future<String> bootstrapBillingSchoolTimezone() {
  return SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
}

/// True when no usable school zone has resolved yet, so callers fall back to
/// device-local rather than silently pretending the device is in UTC.
bool _schoolZoneUnresolved(String tz) =>
    tz.isEmpty ||
    tz.toUpperCase() == SchoolTimezoneResolver.fallbackTimeZone.toUpperCase();

/// School-calendar "today" (date-only) using the most recently resolved zone.
/// Falls back to device-local today when no school zone has resolved yet, so it
/// is safe to call synchronously before [bootstrapBillingSchoolTimezone]
/// settles.
DateTime billingSchoolToday() {
  final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
  if (_schoolZoneUnresolved(tz)) {
    final n = AppTime.now();
    return DateTime(n.year, n.month, n.day);
  }
  return SchoolZoneDateTime.schoolCalendarTodayOnly(tz);
}

/// School wall-clock "now" (date **and** time) as a plain [DateTime]. Use where
/// a timestamp — not just a calendar day — is needed.
DateTime billingSchoolNow() {
  final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
  if (_schoolZoneUnresolved(tz)) return AppTime.now();
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    ServerTimeService.instance.nowUtc(),
    tz,
  );
}

/// Current year in the school calendar — for analytics / statement year pickers
/// that default to "this year".
int billingSchoolCurrentYear() => billingSchoolToday().year;

/// First day of the current school-calendar month (date-only). Used by the
/// "current month" date-range defaults/resets.
DateTime billingSchoolMonthStart() {
  final t = billingSchoolToday();
  return DateTime(t.year, t.month, 1);
}

/// Last day of the current school-calendar month (date-only). `day: 0` of the
/// next month rolls back to the last day of this one.
DateTime billingSchoolMonthEnd() {
  final t = billingSchoolToday();
  return DateTime(t.year, t.month + 1, 0);
}

/// Renders a UTC ISO timestamp from the API as a school-zone wall-clock
/// [DateTime] for display.
DateTime billingDateTimeForDisplayFromIso(String iso) {
  final parsed = DateTime.parse(iso);
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    parsed,
    SchoolTimezoneResolver.lastKnownTimeZone,
  );
}

/// Converts a date + time-of-day picked in the school's wall clock into the
/// corresponding UTC ISO instant for submission.
Future<String> billingUtcIsoFromSchoolWallClock({
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

/// `yyyy-MM-dd` for a date-only value that was picked/held in the school
/// calendar. Billing date payloads (issueDate, dueDate, statement period,
/// range filters) are calendar days, so they must NOT be UTC-shifted — that is
/// what moved them a day for west-of-UTC schools.
String billingYyyyMmDd(DateTime schoolCalendarDate) =>
    '${schoolCalendarDate.year.toString().padLeft(4, '0')}-'
    '${schoolCalendarDate.month.toString().padLeft(2, '0')}-'
    '${schoolCalendarDate.day.toString().padLeft(2, '0')}';

/// `yyyy-MM-dd` of school-calendar today — the default for payload dates.
String billingYyyyMmDdSchoolToday() => billingYyyyMmDd(billingSchoolToday());
