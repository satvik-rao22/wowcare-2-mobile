import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Resolves the logged-in user's `staffCode`.
///
/// Attendance actions must be executed by the logged-in user, so this helper
/// falls back to fetching `staffCode` from the backend when it is missing
/// from local storage.
Future<String> resolveStaffCodeForLoggedInUser() async {
  final storage = serviceLocator<StorageService>();

  final cached = (await storage.getString(StorageKeys.staffCode) ?? '').trim();
  if (cached.isNotEmpty) return cached;

  final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
  final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();

  if (userCode.isEmpty || organizationCode.isEmpty) return '';

  // Best-effort: determine whether the backend expects `schoolCode = '-'`
  // for this org (ORGANIZATION_ADMIN role).
  bool isOrgAdmin = false;
  try {
    final rolesJson = await storage.getString(StorageKeys.roles);
    if (rolesJson != null && rolesJson.trim().isNotEmpty) {
      final decoded = jsonDecode(rolesJson);
      if (decoded is List) {
        for (final r in decoded) {
          if (r is Map) {
            final rOrg = (r['organizationCode'] ?? '').toString().trim();
            final rRole = (r['role'] ?? '').toString().toUpperCase().trim();
            if (rOrg == organizationCode && rRole == 'ORGANIZATION_ADMIN') {
              isOrgAdmin = true;
              break;
            }
          }
        }
      }
    }
  } catch (_) {
    // Non-blocking: keep isOrgAdmin=false and try default fallbacks below.
  }

  // Candidates:
  // - normal: use stored schoolCode
  // - org admin: also try '-'
  final candidates = <String>{};
  if (schoolCode.isNotEmpty) candidates.add(schoolCode);
  if (isOrgAdmin) candidates.add('-');
  if (candidates.isEmpty) candidates.add('-'); // last-resort fallback

  final staffRepository = serviceLocator<StaffRepository>();
  for (final candidateSchoolCode in candidates) {
    final resolved = await staffRepository.getStaffCodeForUser(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: candidateSchoolCode,
    );

    final trimmed = (resolved ?? '').trim();
    if (trimmed.isNotEmpty) {
      await storage.saveString(StorageKeys.staffCode, trimmed);
      await storage.saveString(StorageKeys.staffCodeUser, userCode);
      return trimmed;
    }
  }

  return '';
}

