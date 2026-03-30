import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Resolves the logged-in user's `staffCode`.
///
/// Attendance actions must be executed by the logged-in user, so this helper
/// falls back to fetching `staffCode` from the backend when it is missing
/// from local storage.
Future<String> resolveStaffCodeForLoggedInUser() async {
  final storage = serviceLocator<StorageService>();

  // Only reuse cached staffCode if it belongs to the currently logged-in user.
  final currentUserCode =
      (await storage.getString(StorageKeys.userCode) ?? '').trim();
  final staffCodeOwner =
      (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();
  final cached = (await storage.getString(StorageKeys.staffCode) ?? '').trim();
  if (cached.isNotEmpty &&
      currentUserCode.isNotEmpty &&
      staffCodeOwner == currentUserCode) {
    return cached;
  }

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

class LoggedInStaffDisplay {
  const LoggedInStaffDisplay({
    required this.staffCode,
    required this.fullName,
    required this.profilePhotoUrl,
  });

  final String staffCode;
  final String fullName;
  final String profilePhotoUrl;

  bool get hasStaffCode => staffCode.trim().isNotEmpty;
}

/// Resolves the logged-in staff member's display info (name + photo) for UI.
///
/// - Prefers cached staff profile (fast)
/// - Falls back to API when cache is missing
Future<LoggedInStaffDisplay> resolveLoggedInStaffDisplay() async {
  final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
  if (staffCode.isEmpty) {
    return const LoggedInStaffDisplay(
      staffCode: '',
      fullName: '',
      profilePhotoUrl: '',
    );
  }

  final repo = serviceLocator<StaffRepository>();

  StaffProfile? cached;
  if (repo is StaffRepositoryWithCache) {
    try {
      cached = await (repo as StaffRepositoryWithCache).loadCachedStaffProfile(
        staffCode,
      );
    } catch (_) {
      cached = null;
    }
  }

  if (cached != null) {
    return LoggedInStaffDisplay(
      staffCode: staffCode,
      fullName: cached.fullName.trim(),
      profilePhotoUrl: cached.profilePhotoUrl.trim(),
    );
  }

  try {
    final fresh = await repo.getStaffProfile(staffCode: staffCode);
    return LoggedInStaffDisplay(
      staffCode: staffCode,
      fullName: fresh.fullName.trim(),
      profilePhotoUrl: fresh.profilePhotoUrl.trim(),
    );
  } catch (_) {
    return LoggedInStaffDisplay(
      staffCode: staffCode,
      fullName: '',
      profilePhotoUrl: '',
    );
  }
}
