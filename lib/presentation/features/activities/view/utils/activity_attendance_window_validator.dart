import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
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

Future<Map<String, bool>> _fetchStudentSignedInStatusAtTime({
  required ApiClient apiClient,
  required StorageService storage,
  required List<String> studentCodes,
  required DateTime instantUtc,
}) async {
  if (studentCodes.isEmpty) return const <String, bool>{};
  final endpoint = ApiPaths.url(ApiPaths.studentAttendanceSignInStatusAtTime);
  final allowedClassroomCodes = await resolveAttendanceAllowedClassroomCodes(
    storage: storage,
  );
  final response = await apiClient.client.post<dynamic>(
    endpoint,
    data: <String, dynamic>{
      'studentCodes': studentCodes,
      'allowedClassroomCodes': allowedClassroomCodes,
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
  required StorageService storage,
  required List<String> staffCodes,
  required DateTime instantUtc,
}) async {
  if (staffCodes.isEmpty) return const <String, bool>{};
  final endpoint = ApiPaths.url(ApiPaths.staffAttendanceSignInStatusAtTime);
  final allowedClassroomCodes = await resolveAttendanceAllowedClassroomCodes(
    storage: storage,
  );
  final response = await apiClient.client.post<dynamic>(
    endpoint,
    data: <String, dynamic>{
      'staffCodes': staffCodes,
      'allowedClassroomCodes': allowedClassroomCodes,
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

  final staffCode = (await resolveLoggedInStaffCode() ?? '').trim();
  if (staffCode.isNotEmpty) {
    try {
      final staffStatus = await _fetchStaffSignedInStatusAtTime(
        apiClient: apiClient,
        storage: storage,
        staffCodes: <String>[staffCode],
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
      // Non-blocking on status API failure; avoid false negatives.
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
        storage: storage,
        studentCodes: studentCodes,
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
      // Non-blocking on status API failure; avoid false negatives.
    }
  }
  return true;
}
