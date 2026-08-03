import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

import 'activity_selected_date_prefill.dart';

Future<void> bootstrapActivitySchoolTimezone() async {
  await SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
}

/// Student maps from classroom / Students tab omit [attendanceDate]; the Activities
/// picker includes it. Call after [bootstrapActivitySchoolTimezone] so
/// [attendanceDateYyyyMmDdSchoolToday] uses the resolved school zone.
Future<void> ensureAttendanceDateOnStudentMapsForSchoolToday(
  List<Map<String, dynamic>> maps,
) async {
  await bootstrapActivitySchoolTimezone();
  final dateStr = attendanceDateYyyyMmDdSchoolToday();
  for (final m in maps) {
    if ((m['attendanceDate'] ?? '').toString().trim().isEmpty) {
      m['attendanceDate'] = dateStr;
    }
  }
}

DateTime activityDateTimeForDisplayFromIso(String iso) {
  final parsed = DateTime.parse(iso);
  return SchoolZoneDateTime.dateTimeFromInstantInSchool(
    parsed,
    SchoolTimezoneResolver.lastKnownTimeZone,
  );
}

Future<String> activityUtcIsoFromSchoolWallClock({
  required DateTime date,
  required TimeOfDay time,
}) async {
  final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
  return SchoolZoneDateTime.resolvePickedInstantUtc(
    schoolTimeZone,
    selectedDate: date,
    selectedTime: time,
  ).toIso8601String();
}

/// Placeholder kept so activity screens can keep `const ActivitySchoolTimeZoneHint()`
/// without churn; timezone hint was removed from the UI per product request.
class ActivitySchoolTimeZoneHint extends StatelessWidget {
  const ActivitySchoolTimeZoneHint({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
