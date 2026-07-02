import 'dart:convert';
import 'package:wowcare/data/features/auth/models/login_response_model.dart' show RoleModel;

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
    final matching =
        matchingRolesForOrgSchool(decoded, organizationCode, schoolCode)
            .toList();
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
