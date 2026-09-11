import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';

/// School-calendar "today" using the most recently resolved zone. Falls back
/// to device-local today when no school zone has been resolved yet, so it is
/// safe to call synchronously before
/// `BootstrapSchedulingSchoolTimezoneUseCase` settles.
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
