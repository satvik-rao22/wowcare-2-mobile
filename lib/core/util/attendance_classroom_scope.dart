import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
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
  final roleJson = (await storage.getString(StorageKeys.roles) ?? '')
      .toUpperCase();
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

  final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
      .trim()
      .toUpperCase();
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

  final cachedStaffType = (await storage.getString(StorageKeys.staffType) ?? '')
      .trim()
      .toUpperCase();
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
