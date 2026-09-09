import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';

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

/// The resolved instant for a picked activity date/time, alongside the
/// school-local "HH:mm:ss" string derived from that SAME instant.
///
/// Both fields come from a single [SchoolZoneDateTime.resolvePickedInstantUtc]
/// call, so the top-level `activityDate` ISO value and the `time` parameter
/// value sent in the payload can never disagree: if the picker is still at
/// its untouched default, both carry the real server-synced seconds; if the
/// user changed the date/time, both are truncated to `:00` seconds.
class ActivityResolvedTime {
  final DateTime utcInstant;
  final String iso;
  final String localTimeHms;

  const ActivityResolvedTime({
    required this.utcInstant,
    required this.iso,
    required this.localTimeHms,
  });
}

Future<ActivityResolvedTime> resolveActivityDateTime({
  required DateTime date,
  required TimeOfDay time,
}) async {
  final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
  final utcInstant = SchoolZoneDateTime.resolvePickedInstantUtc(
    schoolTimeZone,
    selectedDate: date,
    selectedTime: time,
  );
  final localDateTime = SchoolZoneDateTime.dateTimeFromInstantInSchool(
    utcInstant,
    schoolTimeZone,
  );
  String two(int v) => v.toString().padLeft(2, '0');
  return ActivityResolvedTime(
    utcInstant: utcInstant,
    iso: utcInstant.toIso8601String(),
    localTimeHms:
        '${two(localDateTime.hour)}:${two(localDateTime.minute)}:${two(localDateTime.second)}',
  );
}

/// Placeholder kept so activity screens can keep `const ActivitySchoolTimeZoneHint()`
/// without churn; timezone hint was removed from the UI per product request.
class ActivitySchoolTimeZoneHint extends StatelessWidget {
  const ActivitySchoolTimeZoneHint({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
