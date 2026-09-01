import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Resolves the logged-in user's `staffCode`.
///
/// Attendance actions must be executed by the logged-in user, so this helper
/// falls back to fetching `staffCode` from the backend when it is missing
/// from local storage.
Future<String> resolveStaffCodeForLoggedInUser({
  bool allowOrganizationLevelFallback = true,
}) async {
  final storage = serviceLocator<StorageService>();
  final staffRepository = serviceLocator<StaffRepository>();

  // Only reuse cached staffCode if it belongs to the currently logged-in user
  // and selected org/school context.
  final currentUserCode = (await storage.getString(StorageKeys.userCode) ?? '')
      .trim();
  final currentOrganizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
  final currentSchoolCode =
      (await storage.getString(StorageKeys.schoolCode) ?? '').trim();

  final rolesJsonEarly = (await storage.getString(StorageKeys.roles) ?? '')
      .trim();
  if (shouldSkipStaffCodeResolutionForContext(
    rolesJson: rolesJsonEarly,
    organizationCode: currentOrganizationCode,
    schoolCode: currentSchoolCode,
  )) {
    await storage.remove(StorageKeys.staffCode);
    await storage.remove(StorageKeys.staffCodeUser);
    await storage.remove(StorageKeys.staffCodeOrganization);
    await storage.remove(StorageKeys.staffCodeSchool);
    return '';
  }

  final staffCodeOwner =
      (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();
  final staffCodeOrganization =
      (await storage.getString(StorageKeys.staffCodeOrganization) ?? '').trim();
  final staffCodeSchool =
      (await storage.getString(StorageKeys.staffCodeSchool) ?? '').trim();
  final cached = (await storage.getString(StorageKeys.staffCode) ?? '').trim();
  if (cached.isNotEmpty &&
      currentUserCode.isNotEmpty &&
      staffCodeOwner == currentUserCode &&
      staffCodeOrganization == currentOrganizationCode &&
      staffCodeSchool == currentSchoolCode) {
    // Re-validate cached mapping against backend to avoid using stale staffCode.
    // Org admins are org-level: the lookup expects '-' and 404s on a real
    // school code, so resolve the right lookup school instead of the raw one.
    try {
      final verified = await staffRepository.getStaffCodeForUser(
        userCode: currentUserCode,
        organizationCode: currentOrganizationCode,
        schoolCode: staffCodeLookupSchoolCode(
          rolesJson: rolesJsonEarly,
          organizationCode: currentOrganizationCode,
          schoolCode: currentSchoolCode,
        ),
      );
      final verifiedTrimmed = (verified ?? '').trim();
      if (verifiedTrimmed.isNotEmpty) {
        if (verifiedTrimmed != cached) {
          await storage.saveString(StorageKeys.staffCode, verifiedTrimmed);
        }
        return verifiedTrimmed;
      }
    } catch (_) {
      // If lookup fails, clear stale cached values and continue fallback resolution.
      await storage.remove(StorageKeys.staffCode);
      await storage.remove(StorageKeys.staffCodeUser);
      await storage.remove(StorageKeys.staffCodeOrganization);
      await storage.remove(StorageKeys.staffCodeSchool);
    }
  }

  final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
  final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
      .trim();

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
  // - org admin: mapped org-level, so the backend expects '-' and 404s on a
  //   real school code. Send '-' only.
  // - normal: use stored schoolCode
  final candidates = <String>{};
  if (isOrgAdmin) {
    candidates.add('-');
  } else if (schoolCode.isNotEmpty) {
    candidates.add(schoolCode);
  }
  if (candidates.isEmpty && allowOrganizationLevelFallback) {
    candidates.add('-'); // last-resort fallback
  }

  for (final candidateSchoolCode in candidates) {
    String? resolved;
    try {
      resolved = await staffRepository.getStaffCodeForUser(
        userCode: userCode,
        organizationCode: organizationCode,
        schoolCode: candidateSchoolCode,
      );
    } catch (_) {
      // Backend can return 404 when no staff mapping exists for a context.
      // Keep trying other candidates and fail gracefully if none resolve.
      continue;
    }

    final trimmed = (resolved ?? '').trim();
    if (trimmed.isNotEmpty) {
      await storage.saveString(StorageKeys.staffCode, trimmed);
      await storage.saveString(StorageKeys.staffCodeUser, userCode);
      await storage.saveString(
        StorageKeys.staffCodeOrganization,
        organizationCode,
      );
      await storage.saveString(StorageKeys.staffCodeSchool, schoolCode);
      return trimmed;
    }
  }

  await storage.remove(StorageKeys.staffCode);
  await storage.remove(StorageKeys.staffCodeUser);
  await storage.remove(StorageKeys.staffCodeOrganization);
  await storage.remove(StorageKeys.staffCodeSchool);
  return '';
}

/// Storage/roles-based fallback for "is the logged-in user a school/org
/// admin?" — used when a `RoleCubit`-aware `BuildContext` isn't available
/// (e.g. from a Cubit, which has no context per the MVVM rule, or a View
/// that's already unmounted). `RoleCubit`'s active persona is the canonical,
/// persona-switch-aware signal — staffType/roles in storage can lag a beat
/// after a persona switch and misresolve a staff/teacher persona as admin —
/// so a mounted View with context should check `RoleCubit` first and only
/// fall back to this when unmounted.
Future<bool> resolveIsStaffAdminPersonaFromStorage() async {
  final storage = serviceLocator<StorageService>();
  final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
      .trim()
      .toUpperCase();

  if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
    return true;
  }

  final rolesJson = await storage.getString(StorageKeys.roles);
  if (rolesJson == null || rolesJson.trim().isEmpty) return false;

  try {
    final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
    return roles.any((r) {
      if (r is! Map<String, dynamic>) return false;
      final roleCode = (r['role'] ?? '').toString().toUpperCase();
      return roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN';
    });
  } catch (_) {
    return false;
  }
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
