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
/// When every role tied to the context is guardian/parent-only, the user has
/// no staff record and the staff lookup returns 404.
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
    final hasNonGuardian = matching.any(
      (m) => !roleStringIsGuardianPersona(m['role'] ?? ''),
    );
    return !hasNonGuardian;
  } catch (_) {
    return false;
  }
}

/// True when any role in the login response is a kiosk persona.
///
/// Kiosk users should skip all post-login APIs (context, staff lookup, profile, PIN)
/// and redirect directly to `/kiosk`.
/// Accepts either RoleModel objects or raw Map objects.
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

      final upperRole = roleStr.toUpperCase();
      if (upperRole.contains('KIOSK')) {
        return true;
      }
    }
  } catch (e) {
    // Log error for debugging
  }
  return false;
}
