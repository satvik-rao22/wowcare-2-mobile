import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/storage_service.dart';
import 'storage_keys.dart';

/// Must stay aligned with [RoleProvider] persona persistence (`selected_role`).
const String kSelectedPersonaRoleKey = 'selected_role';

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
  final prefs = await SharedPreferences.getInstance();
  final role =
      (prefs.getString(kSelectedPersonaRoleKey) ?? 'admin').trim().toLowerCase();
  if (role != 'staff') {
    return <String>[];
  }

  final staffType =
      (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
  if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
    return <String>[];
  }

  final raw =
      (await storage.getString(StorageKeys.staffAllowedClassroomCodes) ?? '')
          .trim();
  if (raw.isEmpty) {
    return <String>[];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return <String>[];
}

/// Adds [allowedClassroomCodes] to a JSON request body for attendance mutations.
Future<void> applyAllowedClassroomCodesToAttendanceBody(
  Map<String, dynamic> body,
  StorageService storage,
) async {
  final codes = await resolveAttendanceAllowedClassroomCodes(storage: storage);
  body['allowedClassroomCodes'] = List<String>.from(codes);
}
