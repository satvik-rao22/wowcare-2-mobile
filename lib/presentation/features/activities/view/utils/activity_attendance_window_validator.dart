import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import '../../utils/resolve_logged_in_staff_code.dart';

/// A transferred student's classroom-scoped "at time" sign-in record can
/// still be keyed to the classroom they were transferred OUT of, so the
/// scoped check below can return "not signed in" for a student who is
/// genuinely present. This window bounds a classroom-agnostic fallback
/// (today's sign-in status, no classroom filter) to only kick in for
/// effectively-"now" submissions, so a real backdated/future check still
/// gets the stricter classroom-scoped answer.
const Duration _fallbackSignInCheckTolerance = Duration(minutes: 10);

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

  // ACTIVE persona (single value), not a scan of the account's full cached
  // roles list below — that list always contains every role the account has
  // across every school, so a dual-role user (e.g. GUARDIAN + STAFF in a
  // different school) would be misdetected as staff regardless of which
  // persona is actually active right now.
  final activeRole =
      (await storage.getString(StorageKeys.activeSchoolRole) ?? '')
          .trim()
          .toUpperCase();
  if (activeRole.isNotEmpty) return allowedStaffPersonas.contains(activeRole);

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
  final instantUtc = SchoolZoneDateTime.resolvePickedInstantUtc(
    ServerTimeService.instance.schoolTimeZone,
    selectedDate: selectedDate,
    selectedTime: selectedTime,
  );
  // Always validate attendance against API, including "current minute"/today.
  // This guarantees latest sign-in state is checked on every submit attempt.
  final classroomCode = _resolveClassroomCodeFromSelectedStudents(students);
  if (classroomCode.isEmpty) return true;

  final shouldValidateStaff = await _shouldRunStaffAtTimeValidation(storage);
  final staffCode = (await resolveLoggedInStaffCode() ?? '').trim();
  if (shouldValidateStaff && staffCode.isNotEmpty) {
    try {
      final staffStatus = await serviceLocator<GetStaffSignInStatusAtTimeUseCase>()(
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
  final ambiguousClassroomStudentCodes = <String>{
    for (final s in students)
      if (s['classroomCodeAmbiguousForDate'] == true)
        (s['studentCode'] ?? '').toString().trim(),
  };

  if (studentCodes.isNotEmpty) {
    try {
      final studentStatus = await serviceLocator<GetStudentSignInStatusAtTimeUseCase>()(
        studentCodes: studentCodes,
        classroomCode: classroomCode,
        instantUtc: instantUtc,
      );
      var notSignedInCodes = <String>[
        for (final code in studentCodes)
          if (studentStatus[code] != true) code,
      ];

      // The classroom-scoped check above can false-positive for a student who
      // was transferred to another classroom but never signed out: their
      // active sign-in record may still be keyed to the OLD classroom, so a
      // query scoped to the (new) classroomCode finds nothing. For
      // effectively-"now" submissions, re-check those specific students with
      // a classroom-agnostic "today" status before blocking them.
      //
      // This fallback only proves the student is signed in SOMEWHERE, not in
      // `classroomCode` specifically — safe only when `classroomCode` was the
      // student's sole classroom that day. When the student had more than one
      // classroom stint that day (a same-day transfer), applying it would
      // wrongly clear a student who is legitimately no longer in the OLD
      // classroom being posted to, defeating the very check this validator
      // exists for. Those students stay excluded from the fallback and are
      // left to the stricter scoped result.
      final fallbackEligibleCodes = notSignedInCodes
          .where((code) => !ambiguousClassroomStudentCodes.contains(code))
          .toList(growable: false);
      if (fallbackEligibleCodes.isNotEmpty &&
          instantUtc
                  .difference(ServerTimeService.instance.nowUtc())
                  .abs() <=
              _fallbackSignInCheckTolerance) {
        try {
          final fallbackStatus =
              await serviceLocator<GetStudentTodaySignInStatusMapUseCase>()(
                  studentCodes: fallbackEligibleCodes);
          notSignedInCodes = notSignedInCodes
              .where((code) =>
                  !fallbackEligibleCodes.contains(code) ||
                  fallbackStatus[code]?.toUpperCase() != 'SIGNED_IN')
              .toList(growable: false);
        } catch (_) {
          // Fallback is best-effort; keep the scoped result on failure.
        }
      }

      final notSignedInNames = <String>[
        for (final code in notSignedInCodes)
          (studentNameByCode[code] == null || studentNameByCode[code]!.isEmpty)
              ? 'Selected student'
              : studentNameByCode[code]!,
      ];
      if (notSignedInNames.isNotEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message:
              'Student(s) must be signed in at the time of posting the activity in this classroom:\n${notSignedInNames.join(', ')}',
          isWarning: true,
        );
        return false;
      }
    } catch (_) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Student(s) must be signed in at the time of posting the activity in this classroom.',
        isWarning: true,
      );
      return false;
    }
  }
  return true;
}
