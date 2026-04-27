import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import '../../utils/resolve_logged_in_staff_code.dart';

String _formatTimeOfDayReadable(TimeOfDay? tod) {
  if (tod == null) return '--';
  final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
  final minute = tod.minute.toString().padLeft(2, '0');
  final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

String _yyyyMmDd(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final yyyy = normalized.year.toString().padLeft(4, '0');
  final mm = normalized.month.toString().padLeft(2, '0');
  final dd = normalized.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}

Future<DateTime?> _selectedInstantUtc({
  required DateTime date,
  required TimeOfDay time,
}) async {
  try {
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
    );
  } catch (_) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

Future<bool> _shouldSkipAtTimeValidationForCurrentTime({
  required DateTime date,
  required DateTime selectedInstantUtc,
  required TimeOfDay selectedTime,
}) async {
  // Fast path: selected instant is effectively "now" in UTC (device clock).
  final deviceNowDiffSeconds =
      selectedInstantUtc.difference(DateTime.now().toUtc()).inSeconds.abs();
  if (deviceNowDiffSeconds <= 180) return true;

  try {
    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    final schoolNow =
        SchoolZoneDateTime.schoolCalendarDateAndTimeNow(schoolTimeZone).$1;
    final nowInstantUtc = SchoolZoneDateTime.utcFromSchoolWallClock(
      schoolTimeZone,
      year: schoolNow.year,
      month: schoolNow.month,
      day: schoolNow.day,
      hour: schoolNow.hour,
      minute: schoolNow.minute,
    );

    // Skip validation when user selected current wall-clock minute.
    final selectedMatchesNowMinute =
        selectedTime.hour == schoolNow.hour && selectedTime.minute == schoolNow.minute;
    if (selectedMatchesNowMinute) return true;

    // Fallback tolerance for clock drift / rounding.
    // When selected date differs due timezone/day rollover edge cases, instant diff
    // is still authoritative for "current time" checks.
    final diffSeconds = selectedInstantUtc.difference(nowInstantUtc).inSeconds.abs();
    return diffSeconds <= 180;
  } catch (_) {
    // Final fallback if school timezone resolution fails.
    final fallbackDiffSeconds =
        selectedInstantUtc.difference(DateTime.now().toUtc()).inSeconds.abs();
    return fallbackDiffSeconds <= 180;
  }
}

Future<Map<String, bool>> _fetchStudentSignedInStatusAtTime({
  required ApiClient apiClient,
  required List<String> studentCodes,
  required String classroomCode,
  required DateTime instantUtc,
}) async {
  if (studentCodes.isEmpty) return const <String, bool>{};
  final endpoint = ApiPaths.url(ApiPaths.studentAttendanceSignInStatusAtTime);
  final response = await apiClient.client.post<dynamic>(
    endpoint,
    data: <String, dynamic>{
      'classroomCode': classroomCode,
      'studentCodes': studentCodes,
      'instant': instantUtc.toIso8601String(),
    },
  );
  final root = response.data;
  if (root is! Map<String, dynamic>) return const <String, bool>{};
  final data = root['data'];
  if (data is! Map) return const <String, bool>{};
  return data.map<String, bool>((key, value) {
    final code = key.toString().trim();
    final isPresent = value == true;
    return MapEntry(code, isPresent);
  });
}

Future<Map<String, bool>> _fetchStaffSignedInStatusAtTime({
  required ApiClient apiClient,
  required List<String> staffCodes,
  required String classroomCode,
  required DateTime instantUtc,
}) async {
  if (staffCodes.isEmpty) return const <String, bool>{};
  final endpoint = ApiPaths.url(ApiPaths.staffAttendanceSignInStatusAtTime);
  final response = await apiClient.client.post<dynamic>(
    endpoint,
    data: <String, dynamic>{
      'classroomCode': classroomCode,
      'staffCodes': staffCodes,
      'instant': instantUtc.toIso8601String(),
    },
  );
  final root = response.data;
  if (root is! Map<String, dynamic>) return const <String, bool>{};
  final data = root['data'];
  if (data is! Map) return const <String, bool>{};
  return data.map<String, bool>((key, value) {
    final code = key.toString().trim();
    final isPresent = value == true || value.toString().toUpperCase() == 'SIGNED_IN';
    return MapEntry(code, isPresent);
  });
}

String _resolveClassroomCodeFromSelectedStudents(
  List<Map<String, dynamic>> students,
) {
  for (final student in students) {
    final dynamic classroomCodeDynamic =
        student['classroomCode'] ?? student['classroomcode'];
    final classroomCode =
        classroomCodeDynamic is String ? classroomCodeDynamic.trim() : '';
    if (classroomCode.isNotEmpty) return classroomCode;
  }
  return '';
}

Future<bool> _shouldRunStaffAtTimeValidation(StorageService storage) async {
  const allowedStaffPersonas = <String>{
    'STAFF',
    'TEACHER',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
  };
  final staffType =
      (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
  if (staffType.isNotEmpty) return allowedStaffPersonas.contains(staffType);

  final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
  if (rolesRaw.isEmpty) return false;
  try {
    final decoded = jsonDecode(rolesRaw);
    if (decoded is List) {
      for (final item in decoded) {
        if (item is! Map) continue;
        final roleCode = (item['role'] ?? item['code'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        if (allowedStaffPersonas.contains(roleCode)) return true;
      }
      return false;
    }
  } catch (_) {
    final rawUpper = rolesRaw.toUpperCase();
    for (final role in allowedStaffPersonas) {
      if (rawUpper.contains(role)) return true;
    }
  }
  return false;
}

Future<bool> validateStudentsWithinAttendanceWindow({
  required BuildContext context,
  required List<Map<String, dynamic>> students,
  DateTime? selectedDate,
  TimeOfDay? selectedTime,
}) async {
  if (students.isEmpty) return true;
  if (selectedDate == null || selectedTime == null) return true;
  final storage = serviceLocator<StorageService>();
  final apiClient = serviceLocator<ApiClient>();
  final selectedTimeDisplay = _formatTimeOfDayReadable(selectedTime);
  final selectedDateDisplay = _yyyyMmDd(selectedDate);
  final instantUtc = await _selectedInstantUtc(
    date: selectedDate,
    time: selectedTime,
  );
  if (instantUtc == null) return true;
  final shouldSkipAtTimeValidation =
      await _shouldSkipAtTimeValidationForCurrentTime(
    date: selectedDate,
    selectedInstantUtc: instantUtc,
    selectedTime: selectedTime,
  );
  if (shouldSkipAtTimeValidation) return true;
  final classroomCode = _resolveClassroomCodeFromSelectedStudents(students);
  if (classroomCode.isEmpty) return true;

  final shouldValidateStaff = await _shouldRunStaffAtTimeValidation(storage);
  final staffCode = (await resolveLoggedInStaffCode() ?? '').trim();
  if (shouldValidateStaff && staffCode.isNotEmpty) {
    try {
      final staffStatus = await _fetchStaffSignedInStatusAtTime(
        apiClient: apiClient,
        staffCodes: <String>[staffCode],
        classroomCode: classroomCode,
        instantUtc: instantUtc,
      );
      final isStaffPresent = staffStatus[staffCode] == true;
      if (!isStaffPresent) {
        CoreUtils.showTopSnackBar(
          context: context,
          message:
              'You cannot mark activity for $selectedDateDisplay at $selectedTimeDisplay because staff is not signed in at that time.',
          isWarning: true,
        );
        return false;
      }
    } catch (_) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to validate staff attendance at the selected time. Please try again.',
        isWarning: true,
      );
      return false;
    }
  }

  final studentCodes = students
      .map((s) => (s['studentCode'] ?? '').toString().trim())
      .where((c) => c.isNotEmpty)
      .toList(growable: false);
  final studentNameByCode = <String, String>{
    for (final s in students)
      (s['studentCode'] ?? '').toString().trim():
          (s['name'] ?? 'Selected student').toString().trim(),
  };

  if (studentCodes.isNotEmpty) {
    try {
      final studentStatus = await _fetchStudentSignedInStatusAtTime(
        apiClient: apiClient,
        studentCodes: studentCodes,
        classroomCode: classroomCode,
        instantUtc: instantUtc,
      );
      for (final code in studentCodes) {
        if (studentStatus[code] != true) {
          final name = studentNameByCode[code];
          CoreUtils.showTopSnackBar(
            context: context,
            message:
                '${name == null || name.isEmpty ? 'Selected student' : name} cannot be marked because the student is not signed in at $selectedTimeDisplay on $selectedDateDisplay.',
            isWarning: true,
          );
          return false;
        }
      }
    } catch (_) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to validate student attendance at the selected time. Please try again.',
        isWarning: true,
      );
      return false;
    }
  }
  return true;
}
