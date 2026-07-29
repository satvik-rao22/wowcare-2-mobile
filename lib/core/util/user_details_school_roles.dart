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
