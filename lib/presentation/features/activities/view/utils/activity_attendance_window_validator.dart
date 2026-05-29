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
  final instantUtc = await _selectedInstantUtc(
    date: selectedDate,
    time: selectedTime,
  );
  if (instantUtc == null) return true;
  // Always validate attendance against API, including "current minute"/today.
  // This guarantees latest sign-in state is checked on every submit attempt.
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
              'The following staff must be signed in before creating the activity.',
          isWarning: true,
        );
        return false;
      }
    } catch (_) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'The following staff must be signed in before creating the activity.',
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
      final notSignedInNames = <String>[
        for (final code in studentCodes)
          if (studentStatus[code] != true)
            (studentNameByCode[code] == null || studentNameByCode[code]!.isEmpty)
                ? 'Selected student'
                : studentNameByCode[code]!,
      ];
      if (notSignedInNames.isNotEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message:
              'The following students must be signed in before creating the activity:\n${notSignedInNames.join(', ')}',
          isWarning: true,
        );
        return false;
      }
    } catch (_) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'The following students must be signed in before creating the activity.',
        isWarning: true,
      );
      return false;
    }
  }
  return true;
}
