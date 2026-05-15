import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

Future<void> bootstrapActivitySchoolTimezone() async {
  await SchoolTimezoneResolver.resolveForCurrentSchool(
    storage: serviceLocator<StorageService>(),
    apiClient: serviceLocator<ApiClient>(),
  );
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
  return SchoolZoneDateTime.utcFromSchoolWallClock(
    schoolTimeZone,
    year: date.year,
    month: date.month,
    day: date.day,
    hour: time.hour,
    minute: time.minute,
  ).toIso8601String();
}
