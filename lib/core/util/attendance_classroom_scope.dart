import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

import '../storage/storage_service.dart';
import 'storage_keys.dart';

bool _isGuardianPersonaRole(String role) {
  final r = role.trim().toUpperCase();
  return r.contains('GUARDIAN') || r.contains('PARENT');
}

bool _isStaffPersonaRole(String role) {
  final r = role.trim().toUpperCase();
  return r.contains('STAFF') || r.contains('TEACHER');
}

Future<String> _resolveActivePersonaRole(StorageService storage) async {
  final activeRole =
      (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
  if (activeRole.isNotEmpty) return activeRole;

  // Fallback for older sessions: infer from available role payload.
  final roleJson = (await storage.getString(StorageKeys.roles) ?? '').toUpperCase();
  if (roleJson.contains('STAFF') || roleJson.contains('TEACHER')) {
    return 'STAFF';
  }
  if (roleJson.contains('GUARDIAN') || roleJson.contains('PARENT')) {
    return 'GUARDIAN';
  }
  return '';
}

/// Encode list query params (e.g. `allowedClassroomCodes`) like the attendance datasource.
final Options attendanceListQueryOptions = Options(
  listFormat: ListFormat.multiCompatible,
);

/// Resolves the `classroomCodes` query param for attendance list APIs.
///
/// - [selectedClassroomCodes]: user-selected filter from the classroom dropdown.
/// - [allowedClassroomCodes]: permission scope for scoped staff (from profile).
///
/// When the user picks classrooms, returns the intersection with allowed scope.
/// When nothing is selected, returns null so the API applies scope via
/// [allowedClassroomCodes] only.
List<String>? resolveAttendanceFilterClassroomCodes({
  List<String>? selectedClassroomCodes,
  required List<String> allowedClassroomCodes,
}) {
  final selected = selectedClassroomCodes
          ?.map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];

  if (allowedClassroomCodes.isEmpty) {
    return selected.isEmpty ? null : List<String>.from(selected);
  }

  final allowedSet = allowedClassroomCodes
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  if (selected.isEmpty) {
    return null;
  }

  final narrowed =
      selected.where((c) => allowedSet.contains(c)).toList(growable: false);
  return narrowed.isEmpty ? null : narrowed;
}

/// Maps classroom dropdown labels (names or codes) to API `classroomCodes`.
List<String>? resolveClassroomNamesToCodes({
  required List<String> selectedNamesOrCodes,
  required List<Classroom> classrooms,
}) {
  if (selectedNamesOrCodes.isEmpty || classrooms.isEmpty) return null;

  final nameToCode = <String, String>{};
  final knownCodes = <String>{};
  for (final c in classrooms) {
    final code = c.code.trim();
    final name = c.name.trim();
    if (code.isNotEmpty) {
      knownCodes.add(code);
    }
    if (name.isNotEmpty) {
      nameToCode[name] = code;
      nameToCode[name.toLowerCase()] = code;
    }
    if (code.isNotEmpty && (name.isEmpty || name == code)) {
      nameToCode[code] = code;
    }
  }

  final codes = <String>[];
  for (final selected in selectedNamesOrCodes) {
    final trimmed = selected.trim();
    if (trimmed.isEmpty) continue;
    final fromName =
        nameToCode[trimmed] ?? nameToCode[trimmed.toLowerCase()];
    if (fromName != null && fromName.isNotEmpty) {
      codes.add(fromName);
    } else if (knownCodes.contains(trimmed)) {
      codes.add(trimmed);
    }
  }

  if (codes.isEmpty) return null;
  return codes.toSet().toList(growable: false);
}

/// Resolves `allowedClassroomCodes` for every attendance API call.
///
/// - Admin / parent / school-admin / org-admin personas → `[]` (no classroom restriction).
/// - Teacher/staff persona → codes from cached staff profile (may be empty).
Future<List<String>> resolveAttendanceAllowedClassroomCodes({
  required StorageService storage,
}) async {
  final activeRole = await _resolveActivePersonaRole(storage);
  // Parent/guardian persona must never send scoped classroom codes.
  if (_isGuardianPersonaRole(activeRole)) {
    return <String>[];
  }
  // Non-staff personas should not be classroom-scoped.
  if (!_isStaffPersonaRole(activeRole)) {
    return <String>[];
  }

  final staffType =
      (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
  if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
    return <String>[];
  }

  List<String> _decodeCodes(String raw) {
    if (raw.trim().isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) {
              if (e is Map) {
                final code = (e['code'] ?? '').toString().trim();
                if (code.isNotEmpty) return code;
              }
              return e.toString().trim();
            })
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return <String>[];
  }

  final raw =
      (await storage.getString(StorageKeys.staffAllowedClassroomCodes) ?? '')
          .trim();
  final cachedCodes = _decodeCodes(raw);
  if (cachedCodes.isNotEmpty) {
    return cachedCodes;
  }

  // Self-heal path:
  // If cache is empty/stale, resolve logged-in staffCode and fetch profile once
  // so attendance APIs can still be scoped correctly.
  try {
    final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    if (staffCode.isEmpty) return <String>[];

    final repo = serviceLocator<StaffRepository>();
    // Use staff/{code}/profile (not my-profile), because my-profile payload
    // may not include allowedClassroomCodes required for attendance scoping.
    final profile = await repo.getStaffProfile(
      staffCode: staffCode,
      forEditStaff: true,
    );

    final profileStaffType = profile.staffType.trim().toUpperCase();
    if (profileStaffType.isNotEmpty) {
      await storage.saveString(StorageKeys.staffType, profile.staffType);
    }
    await storage.saveString(
      StorageKeys.staffAllowedClassroomCodes,
      jsonEncode(profile.allowedClassroomCodes),
    );

    if (profileStaffType == 'SCHOOL_ADMIN' ||
        profileStaffType == 'ORGANIZATION_ADMIN') {
      return <String>[];
    }

    return profile.allowedClassroomCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  } catch (_) {
    return <String>[];
  }
}

/// Primary classroom code for scoped staff personas (teacher/staff), or null
/// for admin/parent personas.
Future<String?> resolveStaffPrimaryClassroomCode({
  required StorageService storage,
}) async {
  final shouldScope = await isAttendanceScopedStaffPersona(storage: storage);
  if (!shouldScope) return null;

  try {
    final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    if (staffCode.isEmpty) return null;

    final repo = serviceLocator<StaffRepository>();
    final profile = await repo.getStaffProfile(
      staffCode: staffCode,
      forEditStaff: true,
    );
    final primary = profile.primaryClassroomCode.trim();
    if (primary.isNotEmpty) return primary;

    final allowed = profile.allowedClassroomCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return allowed.isNotEmpty ? allowed.first : null;
  } catch (_) {
    return null;
  }
}

/// Like [resolveStaffPrimaryClassroomCode] but resolves the staff member's
/// primary classroom for ANY persona — including admins, whose classroom lists
/// are not attendance-scoped. Use this to pre-select the primary classroom on
/// screens that show it to admins too (daily/custom/classroom). Returns null
/// when unavailable; callers should fall back to the top sorted classroom (and
/// must ignore it when it resolves to a non-selectable room like Office).
Future<String?> resolveStaffPrimaryClassroomCodeAnyPersona() async {
  try {
    final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    if (staffCode.isEmpty) return null;

    final repo = serviceLocator<StaffRepository>();
    final profile = await repo.getStaffProfile(
      staffCode: staffCode,
      forEditStaff: true,
    );
    final primary = profile.primaryClassroomCode.trim();
    return primary.isNotEmpty ? primary : null;
  } catch (_) {
    return null;
  }
}

/// Returns true when logged-in persona is a non-admin staff user, for whom
/// classroom lists should be scoped to `allowedClassroomCodes`.
Future<bool> isAttendanceScopedStaffPersona({
  required StorageService storage,
}) async {
  final activeRole = await _resolveActivePersonaRole(storage);
  if (_isGuardianPersonaRole(activeRole)) {
    return false;
  }
  if (!_isStaffPersonaRole(activeRole)) {
    return false;
  }

  final cachedStaffType =
      (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
  if (cachedStaffType == 'SCHOOL_ADMIN' ||
      cachedStaffType == 'ORGANIZATION_ADMIN') {
    return false;
  }
  if (cachedStaffType.isNotEmpty) return true;

  // Fallback when cache is missing: resolve from profile once.
  try {
    final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    if (staffCode.isEmpty) return false;

    final repo = serviceLocator<StaffRepository>();
    final profile = await repo.getStaffProfile(
      staffCode: staffCode,
      forEditStaff: true,
    );
    final profileStaffType = profile.staffType.trim().toUpperCase();

    if (profile.staffType.trim().isNotEmpty) {
      await storage.saveString(StorageKeys.staffType, profile.staffType);
    }
    await storage.saveString(
      StorageKeys.staffAllowedClassroomCodes,
      jsonEncode(profile.allowedClassroomCodes),
    );

    return profileStaffType != 'SCHOOL_ADMIN' &&
        profileStaffType != 'ORGANIZATION_ADMIN';
  } catch (_) {
    return false;
  }
}

/// Adds [allowedClassroomCodes] to a JSON request body for attendance mutations.
Future<void> applyAllowedClassroomCodesToAttendanceBody(
  Map<String, dynamic> body,
  StorageService storage,
) async {
  final codes = await resolveAttendanceAllowedClassroomCodes(storage: storage);
  body['allowedClassroomCodes'] = List<String>.from(codes);
}

// —— STUDENT-attendance cross-class variants ————————————————————————————————
//
// These mirror the resolvers above but additionally relax a scoped teacher to
// "unscoped" (all classrooms) when the active school has
// `allowTeacherCrossClassAttendance` enabled — so teachers view and act on
// students from any classroom, like an admin. The base resolvers are left
// untouched so STAFF attendance, messaging, newsletter and classroom/student
// lists keep their current scoping.

/// STUDENT-attendance variant of [resolveAttendanceAllowedClassroomCodes].
///
/// Returns `[]` (no restriction) for admin/parent personas as usual, and also
/// for scoped teachers when cross-class attendance is enabled for the active
/// school. Otherwise returns the teacher's allowed classroom codes.
Future<List<String>> resolveStudentAttendanceAllowedClassroomCodes({
  required StorageService storage,
}) async {
  final base = await resolveAttendanceAllowedClassroomCodes(storage: storage);
  // Admin/parent personas are already unscoped — nothing to relax.
  if (base.isEmpty) return base;
  final crossClass = await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
    storage: storage,
  );
  return crossClass ? <String>[] : base;
}

/// STUDENT-attendance variant of [isAttendanceScopedStaffPersona]: a scoped
/// teacher is treated as unscoped when cross-class attendance is enabled.
Future<bool> isStudentAttendanceScopedStaffPersona({
  required StorageService storage,
}) async {
  final scoped = await isAttendanceScopedStaffPersona(storage: storage);
  if (!scoped) return false;
  final crossClass = await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
    storage: storage,
  );
  return !crossClass;
}

/// STUDENT-attendance variant of [applyAllowedClassroomCodesToAttendanceBody].
Future<void> applyStudentAllowedClassroomCodesToAttendanceBody(
  Map<String, dynamic> body,
  StorageService storage,
) async {
  final codes = await resolveStudentAttendanceAllowedClassroomCodes(
    storage: storage,
  );
  body['allowedClassroomCodes'] = List<String>.from(codes);
}
