import 'package:flutter/material.dart';
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
  final parsed = DateTime.parse(iso);
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    parsed,
    SchoolTimezoneResolver.lastKnownTimeZone,
  );
}

/// Placeholder kept so activity screens can keep `const ActivitySchoolTimeZoneHint()`
/// without churn; timezone hint was removed from the UI per product request.
class ActivitySchoolTimeZoneHint extends StatelessWidget {
  const ActivitySchoolTimeZoneHint({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
