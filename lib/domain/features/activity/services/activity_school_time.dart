import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';

/// Pure — reads only [SchoolTimezoneResolver.lastKnownTimeZone] (a static,
/// already-resolved cache), so it carries no `StorageService`/`ApiClient`
/// dependency and needs no cubit seam. Everything that DOES need to resolve
/// the zone lives on `ActivityEditorCubit` (`resolveSchoolTimezone`,
/// `bootstrapSchoolTimezone`, `activityUtcIsoFromSchoolWallClock`,
/// `resolveActivityDateTime`, `ensureAttendanceDateOnStudentMapsForSchoolToday`)
/// — call through the screen's `_editor` instead of resolving
/// `StorageService`/`ApiClient` directly here.
DateTime activityDateTimeForDisplayFromIso(String iso) {
  final parsed = SchoolZoneDateTime.parseUtcInstant(iso);
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    parsed,
    SchoolTimezoneResolver.lastKnownTimeZone,
  );
}
