import 'dart:convert';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// Distinct backend role strings for [schoolCode] within [organizationCode] from `/users/details` payloads.
List<String> distinctActiveRolesForCurrentSchoolFromUserDetails(
  List<Map<String, dynamic>> users,
  String organizationCode,
  String schoolCode,
) {
  final org = organizationCode.trim();
  final school = schoolCode.trim();
  if (org.isEmpty || school.isEmpty) return [];

  final seen = <String>{};
  final out = <String>[];

  for (final user in users) {
    final uOrg = (user['organizationCode'] ?? '').toString().trim();
    if (uOrg != org) continue;
    final schools = user['schools'];
    if (schools is! List) continue;
    for (final s in schools) {
      if (s is! Map) continue;
      final m = Map<String, dynamic>.from(s);
      final sc = (m['schoolCode'] ?? '').toString().trim();
      if (sc != school) continue;
      final status = (m['status'] ?? 'ACTIVE').toString().toUpperCase().trim();
      if (status.isNotEmpty && status != 'ACTIVE') continue;
      final role = (m['role'] ?? '').toString().trim();
      if (role.isEmpty) continue;
      final key = role.toUpperCase();
      if (seen.add(key)) {
        out.add(role);
      }
    }
  }
  return out;
}

/// Backend status (upper-cased, e.g. `ACTIVE`, `PENDING`) for [schoolCode]
/// within [organizationCode] from a `/users/details` payload snapshot.
/// Returns null when the school isn't present in the snapshot — callers
/// should treat an unknown status as active so a stale/incomplete snapshot
/// never locks a legitimate user out.
String? schoolStatusFromUserDetails(
  List<Map<String, dynamic>> users,
  String organizationCode,
  String schoolCode,
) {
  final org = organizationCode.trim();
  final school = schoolCode.trim();
  if (org.isEmpty || school.isEmpty) return null;

  for (final user in users) {
    final uOrg = (user['organizationCode'] ?? '').toString().trim();
    if (uOrg != org) continue;
    final schools = user['schools'];
    if (schools is! List) continue;
    for (final s in schools) {
      if (s is! Map) continue;
      final m = Map<String, dynamic>.from(s);
      final sc = (m['schoolCode'] ?? '').toString().trim();
      if (sc != school) continue;
      final status = (m['status'] ?? '').toString().trim().toUpperCase();
      return status.isEmpty ? null : status;
    }
  }
  return null;
}

Future<List<Map<String, dynamic>>> readCachedUserAccessDetailsUsers(
  StorageService storage,
) async {
  final raw = await storage.getString(StorageKeys.userAccessDetails);
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  } catch (_) {}
  return [];
}

/// Resolves the raw backend role string (e.g. `ORGANIZATION_ADMIN`,
/// `SCHOOL_ADMIN`, `GUARDIAN`) for the CURRENTLY ACTIVE persona — the single
/// source of truth every request-scoping decision (the `x-role` header, and
/// any endpoint that also wants the role as an explicit body/query field)
/// should use, so a dual-role account's active persona is never ambiguous
/// between two different resolution paths drifting out of sync.
///
/// 1. [StorageKeys.activeSchoolRole] if set — the persona the user actually
///    switched to.
/// 2. Otherwise, the role scoped to the CURRENT org+school from the cached
///    `/users/details` snapshot — never a role belonging to a different
///    school on the same dual-role account.
/// 3. Otherwise, the first role in the raw login `roles` list (last resort;
///    only reachable when there's no cached snapshot at all).
Future<String> resolveActiveBackendRole(StorageService storage) async {
  final activeStored =
      (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
  if (activeStored.isNotEmpty) return activeStored;

  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
  final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
      .trim();

  if (organizationCode.isNotEmpty && schoolCode.isNotEmpty) {
    final users = await readCachedUserAccessDetailsUsers(storage);
    final distinctRoles = distinctActiveRolesForCurrentSchoolFromUserDetails(
      users,
      organizationCode,
      schoolCode,
    );
    if (distinctRoles.isNotEmpty) return distinctRoles.first.trim();
  }

  final raw = (await storage.getString(StorageKeys.roles) ?? '').trim();
  if (raw.isEmpty) return '';
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return ((decoded.first as Map)['role'] ?? '').toString().trim();
    }
  } catch (_) {}
  return '';
}
