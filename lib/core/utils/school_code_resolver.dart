import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/user_details_school_roles.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Resolves the active school code for API calls tied to the logged-in user.
///
/// [StorageKeys.schoolCode] may be `-` for organization-level personas; this
/// helper recovers a concrete school from login context, saved selections, roles,
/// or the staff profile when needed.
Future<String> resolveLoggedInSchoolCode(StorageService storage) async {
  String? pick(String? raw) {
    final code = (raw ?? '').trim();
    if (code.isEmpty || code == '-') return null;
    return code;
  }

  final fromStorage = pick(await storage.getString(StorageKeys.schoolCode));
  if (fromStorage != null) return fromStorage;

  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();

  final loginContext = await storage.getJson(StorageKeys.loginContext);
  if (loginContext != null) {
    final fromContext = pick(
      loginContext['LastLoginSchoolCode']?.toString(),
    );
    if (fromContext != null) return fromContext;
  }

  if (organizationCode.isNotEmpty) {
    final fromOrgSchoolList =
        await _schoolFromOrganizationsAndSchools(storage, organizationCode);
    if (fromOrgSchoolList != null) return fromOrgSchoolList;

    final fromRoles = await _schoolFromRoles(storage, organizationCode);
    if (fromRoles != null) return fromRoles;

    final fromUserDetails =
        await _schoolFromUserAccessDetails(storage, organizationCode);
    if (fromUserDetails != null) return fromUserDetails;
  }

  try {
    final staffCode = await resolveStaffCodeForLoggedInUser();
    if (staffCode.isNotEmpty) {
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: staffCode,
      );
      final fromProfile = pick(profile.schoolCode);
      if (fromProfile != null) return fromProfile;
    }
  } catch (_) {}

  return '';
}

Future<String?> _schoolFromOrganizationsAndSchools(
  StorageService storage,
  String organizationCode,
) async {
  final rawList =
      (await storage.getString(StorageKeys.organizationsAndSchools) ?? '').trim();
  if (rawList.isEmpty) return null;

  try {
    final decoded = jsonDecode(rawList);
    if (decoded is! List) return null;
    for (final item in decoded) {
      if (item is! Map) continue;
      final org = (item['organizationCode'] ?? '').toString().trim();
      final school = (item['schoolCode'] ?? '').toString().trim();
      if (org == organizationCode && school.isNotEmpty && school != '-') {
        return school;
      }
    }
  } catch (_) {}

  return null;
}

Future<String?> _schoolFromRoles(
  StorageService storage,
  String organizationCode,
) async {
  final rolesJson = (await storage.getString(StorageKeys.roles) ?? '').trim();
  if (rolesJson.isEmpty) return null;

  try {
    final decoded = jsonDecode(rolesJson);
    if (decoded is! List) return null;
    for (final role in decoded) {
      if (role is! Map) continue;
      final org = (role['organizationCode'] ?? '').toString().trim();
      final school = (role['schoolCode'] ?? '').toString().trim();
      if (org == organizationCode && school.isNotEmpty && school != '-') {
        return school;
      }
    }
  } catch (_) {}

  return null;
}

Future<String?> _schoolFromUserAccessDetails(
  StorageService storage,
  String organizationCode,
) async {
  final users = await readCachedUserAccessDetailsUsers(storage);
  for (final user in users) {
    final org = (user['organizationCode'] ?? '').toString().trim();
    if (org != organizationCode) continue;
    final schools = user['schools'];
    if (schools is! List) continue;
    for (final schoolEntry in schools) {
      if (schoolEntry is! Map) continue;
      final school = (schoolEntry['schoolCode'] ?? '').toString().trim();
      if (school.isNotEmpty && school != '-') {
        return school;
      }
    }
  }
  return null;
}
