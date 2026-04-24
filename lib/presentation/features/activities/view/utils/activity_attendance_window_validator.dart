import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';

TimeOfDay? _parseHmsToTimeOfDay(String? raw) {
  if (raw == null) return null;
  final parts = raw.trim().split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return TimeOfDay(hour: h, minute: m);
}

int _minutesOfDay(TimeOfDay t) => (t.hour * 60) + t.minute;

String _formatHmsReadable(String? raw) {
  final tod = _parseHmsToTimeOfDay(raw);
  if (tod == null) return '--';
  final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
  final minute = tod.minute.toString().padLeft(2, '0');
  final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

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

Future<(String? signIn, String? signOut)> _fetchWindowFromStudentProfileApi({
  required ApiClient apiClient,
  required StorageService storage,
  required String studentCode,
  required String attendanceDate,
  String? classroomCode,
}) async {
  final endpoint = ApiPaths.urlWithBase(
    ApiPaths.studentAttendanceProfile,
    ApiConstants.attendanceBaseUrl,
  );
  final allowedClassroomCodes = await resolveAttendanceAllowedClassroomCodes(
    storage: storage,
  );
  DateTime selectedDay;
  try {
    selectedDay = DateTime.parse(attendanceDate);
  } catch (_) {
    selectedDay = DateTime.now();
  }
  final fromRange = DateTime(selectedDay.year, selectedDay.month, 1);
  final toRange = DateTime(selectedDay.year, selectedDay.month + 1, 0);

  final queryParameters = <String, dynamic>{
    'studentCode': studentCode,
    'fromAttendanceDate': _yyyyMmDd(fromRange),
    'toAttendanceDate': _yyyyMmDd(toRange),
    'page': 0,
    'size': 100,
    'sort': <String>['attendanceDate,desc'],
    'allowedClassroomCodes': List<String>.from(allowedClassroomCodes),
  };
  final response = await apiClient.client.get<dynamic>(
    endpoint,
    queryParameters: queryParameters,
    options: attendanceListQueryOptions,
  );

  final root = response.data;
  if (root is! Map<String, dynamic>) return (null, null);
  final data = root['data'] as Map<String, dynamic>? ?? {};
  final records = data['records'] as Map<String, dynamic>? ?? {};
  final content = records['content'] as List<dynamic>? ?? const [];
  if (content.isEmpty) return (null, null);

  final rows = content
      .whereType<Map>()
      .cast<Map<String, dynamic>>()
      .where((r) => (r['attendanceDate'] ?? '').toString().trim() == attendanceDate)
      .toList();
  if (rows.isEmpty) return (null, null);
  // Important: do NOT lock to one classroom row for transfers.
  // A student can move classrooms in same day; end-time may exist on another row.
  final source = rows;

  int? startMins;
  int? endMins;
  String? startRaw;
  String? endRaw;

  for (final row in source) {
    final inRaw = (row['signedInTime'] ?? row['transferTime'] ?? '')
        .toString()
        .trim();
    final outRaw = (row['signedOutTime'] ?? row['nextActionTime'] ?? '')
        .toString()
        .trim();

    final inTod = _parseHmsToTimeOfDay(inRaw.isEmpty ? null : inRaw);
    final outTod = _parseHmsToTimeOfDay(outRaw.isEmpty ? null : outRaw);
    if (inTod != null) {
      final mins = _minutesOfDay(inTod);
      if (startMins == null || mins < startMins) {
        startMins = mins;
        startRaw = inRaw;
      }
    }
    if (outTod != null) {
      final mins = _minutesOfDay(outTod);
      if (endMins == null || mins > endMins) {
        endMins = mins;
        endRaw = outRaw;
      }
    }
  }

  return (startRaw, endRaw);
}

Future<bool> validateStudentsWithinAttendanceWindow({
  required BuildContext context,
  required List<Map<String, dynamic>> students,
  DateTime? selectedDate,
  TimeOfDay? selectedTime,
}) async {
  if (students.isEmpty) return true;
  final storage = serviceLocator<StorageService>();
  final apiClient = serviceLocator<ApiClient>();
  final fallbackDate = selectedDate ?? DateTime.now();
  final effectiveSelectedTime = selectedTime;
  final selectedTimeMins =
      effectiveSelectedTime != null ? _minutesOfDay(effectiveSelectedTime) : null;
  final selectedTimeDisplay = _formatTimeOfDayReadable(effectiveSelectedTime);

  for (final student in students) {
    String? signInRaw = (student['signedInTime'] as String?)?.trim();
    String? signOutRaw = (student['signedOutTime'] as String?)?.trim();
    final name = (student['name'] ?? 'Selected student').toString();
    final studentCode = (student['studentCode'] ?? '').toString().trim();
    final classroomCode = (student['classroomCode'] ?? '').toString().trim();
    final attendanceDateRaw = (student['attendanceDate'] ?? '').toString().trim();
    final attendanceDate = attendanceDateRaw.isNotEmpty
        ? attendanceDateRaw
        : _yyyyMmDd(fallbackDate);

    if (studentCode.isNotEmpty) {
      try {
        final profileWindow = await _fetchWindowFromStudentProfileApi(
          apiClient: apiClient,
          storage: storage,
          studentCode: studentCode,
          attendanceDate: attendanceDate,
          classroomCode: classroomCode,
        );
        signInRaw = profileWindow.$1?.trim() ?? signInRaw;
        signOutRaw = profileWindow.$2?.trim() ?? signOutRaw;
      } catch (_) {
        // Fall back to student map times when profile API fails.
      }
    }

    final signIn = _parseHmsToTimeOfDay(signInRaw);
    final signOut = _parseHmsToTimeOfDay(signOutRaw);
    final signInDisplay = _formatHmsReadable(signInRaw);
    final signOutDisplay = _formatHmsReadable(signOutRaw);

    if (signIn == null || signOut == null) {
      final reason = signIn == null
          ? 'sign-in time is missing'
          : 'student is not signed out yet';
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            '$name cannot be marked because $reason (window: $signInDisplay - $signOutDisplay). Selected activity time: $selectedTimeDisplay.',
        isWarning: true,
      );
      return false;
    }

    final signInMins = _minutesOfDay(signIn);
    final signOutMins = _minutesOfDay(signOut);
    // Validate against the time the user is recording the activity for.
    // School "current time" is irrelevant; we compare the picked activity time.
    if (selectedTimeMins != null &&
        (selectedTimeMins < signInMins || selectedTimeMins > signOutMins)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            '$name can be marked only between $signInDisplay and $signOutDisplay. Selected activity time: $selectedTimeDisplay.',
        isWarning: true,
      );
      return false;
    }
  }
  return true;
}
