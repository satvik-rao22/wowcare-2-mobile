import 'dart:convert';
import 'package:wowcare/data/features/auth/models/login_response_model.dart'
    show RoleModel;

/// True for parent/guardian API personas (not staff/teachers).
bool roleStringIsGuardianPersona(String role) {
  final u = role.toUpperCase().trim();
  return u == 'GUARDIAN' ||
      u == 'PARENT' ||
      u.contains('GUARDIAN') ||
      u.contains('PARENT');
}

/// True for kiosk personas (not staff/teachers/guardians).
bool roleStringIsKioskPersona(String role) {
  final u = role.toUpperCase().trim();
  return u == 'KIOSK';
}

/// True for staff/teacher personas (not guardian/parent, not kiosk).
bool roleStringIsStaffPersona(String role) {
  final u = role.toUpperCase().trim();
  return u.contains('STAFF') || u.contains('TEACHER');
}

/// Collapses any backend role string to the coarse persona the UI gates on.
/// Mirrors `RoleCubit._personaFamily` — kept in sync so a persona resolved
/// here (e.g. from [lastUsedPersonaFamily]) always lands in the same bucket
/// the cubit itself would assign it.
String personaFamilyForRole(String backendRole) {
  final r = backendRole.trim().toLowerCase();
  if (r.contains('kiosk')) return 'kiosk';
  if (r.contains('guardian') || r.contains('parent')) return 'parent';
  if (r.contains('staff') || r.contains('teacher')) return 'staff';
  return 'admin';
}

/// The persona family a multi-persona account should reopen on for a fresh
/// login, derived from the durable "last used persona" record — `null` when
/// there's no usable record.
///
/// [lastUsedPersonaRoleJson] is the raw `{"userCode": ..., "role": ...}`
/// value persisted at `StorageKeys.lastUsedPersonaRole` (survives logout,
/// unlike `activeSchoolRole`). Returns `null` — so the caller falls through
/// to the admin/staff-priority default — when: nothing is stored yet (fresh
/// install / first-ever login), the record belongs to a different account
/// (userCode mismatch, e.g. a different user on a shared device), or that
/// persona family is no longer among [currentRolesJson] (the just-completed
/// login's roles list).
String? lastUsedPersonaFamily({
  required String lastUsedPersonaRoleJson,
  required String currentUserCode,
  required String currentRolesJson,
}) {
  final raw = lastUsedPersonaRoleJson.trim();
  final userCode = currentUserCode.trim();
  if (raw.isEmpty || userCode.isEmpty) return null;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final storedUserCode = (decoded['userCode'] ?? '').toString().trim();
    final storedRole = (decoded['role'] ?? '').toString().trim();
    if (storedUserCode.isEmpty ||
        storedRole.isEmpty ||
        storedUserCode != userCode) {
      return null;
    }

    final family = personaFamilyForRole(storedRole);
    final rolesRaw = currentRolesJson.trim();
    if (rolesRaw.isEmpty) return null;
    final rolesDecoded = jsonDecode(rolesRaw);
    if (rolesDecoded is! List) return null;
    final stillAvailable = rolesDecoded.any((r) {
      if (r is! Map) return false;
      final roleStr = (r['role'] ?? r['Role'] ?? '').toString();
      return personaFamilyForRole(roleStr) == family;
    });
    return stillAvailable ? family : null;
  } catch (_) {
    return null;
  }
}

/// Derives the coarse persona family (`kiosk` / `staff` / `admin` / `parent`)
/// a multi-persona account should default into when no active persona has
/// been resolved/persisted yet.
///
/// Priority is kiosk > staff > admin > parent: a dual-role account (e.g.
/// SCHOOL_ADMIN + GUARDIAN) must default to the admin/staff persona instead
/// of being silently downgraded to the parent experience just because a
/// guardian role also appears somewhere in the payload.
String derivePersonaFamilyFromRolesJson(String rolesJson) {
  final raw = rolesJson.trim();
  if (raw.isEmpty) return 'admin';

  List<dynamic>? roles;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) roles = decoded;
  } catch (_) {
    // Fall through to legacy substring heuristics below.
  }

  if (roles != null) {
    bool hasKiosk = false,
        hasStaff = false,
        hasAdmin = false,
        hasGuardian = false;
    for (final r in roles) {
      if (r is! Map) continue;
      final roleStr = (r['role'] ?? r['Role'] ?? '').toString();
      if (roleStringIsKioskPersona(roleStr)) {
        hasKiosk = true;
      } else if (roleStringIsStaffPersona(roleStr)) {
        hasStaff = true;
      } else if (roleStringIsGuardianPersona(roleStr)) {
        hasGuardian = true;
      } else if (roleStr.trim().isNotEmpty) {
        hasAdmin = true;
      }
    }
    if (hasKiosk) return 'kiosk';
    if (hasStaff) return 'staff';
    if (hasAdmin) return 'admin';
    if (hasGuardian) return 'parent';
    return 'admin';
  }

  // Legacy fallback: raw JSON couldn't be parsed as a list — scan the string
  // directly, same priority order as above.
  final u = raw.toUpperCase();
  if (u.contains('KIOSK')) return 'kiosk';
  if (u.contains('STAFF') || u.contains('TEACHER')) return 'staff';
  if (u.contains('GUARDIAN') || u.contains('PARENT')) return 'parent';
  return 'admin';
}

/// True when [rolesJson] is the login roles payload and includes a parent/guardian role.
///
/// Handles the common `[{"role":"GUARDIAN",...}]` shape (not matched by naive
/// `roles.contains('GUARDIAN')` on the raw JSON string when formatting differs).
bool rolesJsonIndicatesGuardianLogin(String rolesJson) {
  final raw = rolesJson.trim();
  if (raw.isEmpty) return false;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.any((r) {
        if (r is! Map) return false;
        final role = (r['role'] ?? r['Role'] ?? '').toString();
        return roleStringIsGuardianPersona(role);
      });
    }
  } catch (_) {
    // Fall through to legacy string heuristics.
  }
  final u = raw.toUpperCase();
  return u.contains('GUARDIAN') || u.contains('PARENT');
}

/// Roles that match [organizationCode] and [schoolCode].
///
/// When [schoolCode] is non-empty, a role must match that school or have an
/// empty school (org-wide) to be included.
Iterable<Map<String, String>> matchingRolesForOrgSchool(
  List<dynamic> rolesList,
  String organizationCode,
  String schoolCode,
) sync* {
  final org = organizationCode.trim();
  final school = schoolCode.trim();
  if (org.isEmpty) return;
  for (final r in rolesList) {
    if (r is! Map) continue;
    final m = Map<String, dynamic>.from(r);
    final rOrg = (m['organizationCode'] ?? '').toString().trim();
    if (rOrg != org) continue;
    final rSchool = (m['schoolCode'] ?? '').toString().trim();
    if (school.isNotEmpty &&
        rSchool.isNotEmpty &&
        rSchool != school &&
        rSchool != '-') {
      continue;
    }
    yield {
      'role': (m['role'] ?? '').toString(),
      'organizationCode': rOrg,
      'schoolCode': rSchool,
    };
  }
}

/// Whether to skip `GET /staff/code` for this org/school context.
///
/// When every role tied to the context is guardian/parent-only OR kiosk-only,
/// the user has no staff record and the staff lookup returns 404.
/// Kiosk users are specifically excluded from staff code resolution because
/// they are not mapped in the staff system — they authenticate via PIN.
bool shouldSkipStaffCodeResolutionForContext({
  required String rolesJson,
  required String organizationCode,
  required String schoolCode,
}) {
  if (rolesJson.trim().isEmpty) return false;
  try {
    final decoded = jsonDecode(rolesJson);
    if (decoded is! List<dynamic>) return false;
    final matching = matchingRolesForOrgSchool(
      decoded,
      organizationCode,
      schoolCode,
    ).toList();
    if (matching.isEmpty) return false;

    // Check if any role is kiosk — if so, skip staff code resolution entirely
    final hasKiosk = matching.any(
      (m) => roleStringIsKioskPersona(m['role'] ?? ''),
    );
    if (hasKiosk) return true;

    // If no kiosk role, skip only if all roles are guardian/parent
    final hasNonGuardian = matching.any(
      (m) => !roleStringIsGuardianPersona(m['role'] ?? ''),
    );
    return !hasNonGuardian;
  } catch (_) {
    return false;
  }
}

/// True when [rolesJson] (the login roles payload) contains an
/// `ORGANIZATION_ADMIN` role for [organizationCode].
bool rolesJsonIndicatesOrgAdmin(String rolesJson, String organizationCode) {
  final org = organizationCode.trim();
  if (rolesJson.trim().isEmpty || org.isEmpty) return false;
  try {
    final decoded = jsonDecode(rolesJson);
    if (decoded is! List) return false;
    return decoded.any((r) {
      if (r is! Map) return false;
      final rOrg = (r['organizationCode'] ?? '').toString().trim();
      final rRole = (r['role'] ?? '').toString().toUpperCase().trim();
      return rOrg == org && rRole == 'ORGANIZATION_ADMIN';
    });
  } catch (_) {
    return false;
  }
}

/// The `schoolCode` to send to `GET /staff/code` for this context.
///
/// ORGANIZATION_ADMINs are mapped org-level: the backend expects `'-'` and
/// returns 404 for a real school code. Every other persona uses the real
/// selected school.
String staffCodeLookupSchoolCode({
  required String rolesJson,
  required String organizationCode,
  required String schoolCode,
}) {
  return rolesJsonIndicatesOrgAdmin(rolesJson, organizationCode)
      ? '-'
      : schoolCode.trim();
}

/// True when any role in the login response is a kiosk persona.
///
/// Kiosk users should skip all post-login APIs (context, staff lookup, profile, PIN)
/// and redirect directly to `/kiosk`.
/// Accepts either RoleModel objects or raw Map objects.
/// Uses EXACT matching to avoid false positives with roles like STAFF_KIOSK.
bool loginResponseIsKioskUser(List<dynamic> roles) {
  try {
    for (final role in roles) {
      String roleStr = '';

      // Handle RoleModel objects (from LoginResponseModel.roles)
      if (role is RoleModel) {
        roleStr = role.role;
      }
      // Handle raw Map objects (from JSON)
      else if (role is Map) {
        roleStr = (role['role'] ?? '').toString();
      }
      // Skip anything else
      else {
        continue;
      }

      final upperRole = roleStr.toUpperCase().trim();
      // Exact match only — not .contains() to avoid matching STAFF_KIOSK or similar
      if (upperRole == 'KIOSK') {
        return true;
      }
    }
  } catch (e) {
    // Log error for debugging
  }
  return false;
}

/// SUPERADMIN is a web-portal-only role. The mobile app must block these
/// accounts at login (no session is established). Accepts RoleModel or raw Maps.
bool loginResponseIsSuperAdmin(List<dynamic> roles) {
  try {
    for (final role in roles) {
      String roleStr = '';
      if (role is RoleModel) {
        roleStr = role.role;
      } else if (role is Map) {
        roleStr = (role['role'] ?? '').toString();
      } else {
        continue;
      }
      if (roleStr.toUpperCase().trim() == 'SUPERADMIN') {
        return true;
      }
    }
  } catch (_) {
    // Treat parse errors as "not superadmin" — fail open to normal handling.
  }
  return false;
}
