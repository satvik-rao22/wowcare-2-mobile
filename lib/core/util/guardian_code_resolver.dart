import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

/// Composes `"first last"` from persisted profile fields (resolver-owned; callers
/// use this instead of assembling names ad hoc).
Future<String?> readCachedGuardianProfileDisplayLine() async {
  final storage = serviceLocator<StorageService>();
  final fn =
      (await storage.getString(StorageKeys.guardianProfileFirstName) ?? '')
          .trim();
  final ln =
      (await storage.getString(StorageKeys.guardianProfileLastName) ?? '')
          .trim();
  final line = '$fn $ln'.trim();
  return line.isNotEmpty ? line : null;
}

String _guardianRecordCodeFromProfileMap(Map<String, dynamic> data) {
  final code =
      (data['code'] ??
              data['guardianCode'] ??
              data['GuardianCode'] ??
              data['parentCode'] ??
              data['ParentCode'] ??
              '')
          .toString()
          .trim();
  return code;
}

Future<void> _persistGuardianProfileSnapshot({
  required StorageService storage,
  required Map<String, dynamic> data,
  required String userCode,
  required String schoolCode,
  required String organizationCode,
}) async {
  final code = _guardianRecordCodeFromProfileMap(data);
  final fn =
      (data['firstName'] ?? data['FirstName'] ?? data['first_name'] ?? '')
          .toString()
          .trim();
  final ln = (data['lastName'] ?? data['LastName'] ?? data['last_name'] ?? '')
      .toString()
      .trim();
  final photoAssetCode =
      (data['profilePhotoAssetCode'] ??
              data['photoAssetCode'] ??
              data['profileImageAssetCode'] ??
              '')
          .toString()
          .trim();
  final photoUrl =
      (data['profilePhotoUrl'] ??
              data['photoUrl'] ??
              data['profileImageUrl'] ??
              data['imageUrl'] ??
              '')
          .toString()
          .trim();
  if (code.isNotEmpty) {
    await storage.saveString(StorageKeys.guardianCode, code);
    await storage.saveString(StorageKeys.guardianCodeUser, userCode);
    await storage.saveString(StorageKeys.guardianCodeSchool, schoolCode);
    await storage.saveString(
      StorageKeys.guardianCodeOrganization,
      organizationCode,
    );
  }
  await storage.saveString(StorageKeys.guardianProfileFirstName, fn);
  await storage.saveString(StorageKeys.guardianProfileLastName, ln);
  await storage.saveString(
    StorageKeys.guardianProfileAssetCode,
    photoAssetCode,
  );
  await storage.saveString(StorageKeys.guardianProfilePhotoUrl, photoUrl);
}

/// Always calls `GET /api/v1/guardian/profile` (when persona + context allow) and
/// refreshes persisted code + names. Prefer on guardian app/session bootstrap.
///
/// Returns `data.code` on success; on failure returns any previously cached code.
Future<String> refreshGuardianProfileSnapshotForLoggedInUser() async {
  final storage = serviceLocator<StorageService>();

  final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
  if (rolesRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(rolesRaw);
      if (decoded is List) {
        final hasGuardianPersona = decoded.any((r) {
          if (r is! Map) return false;
          final role = (r['role'] ?? '').toString();
          return roleStringIsGuardianPersona(role);
        });
        if (!hasGuardianPersona) return '';
      }
    } catch (_) {
      final u = rolesRaw.toUpperCase();
      if (!u.contains('GUARDIAN') && !u.contains('PARENT')) {
        return '';
      }
    }
  }

  final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
  final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
      .trim();
  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();

  if (userCode.isEmpty || schoolCode.isEmpty || organizationCode.isEmpty) {
    return (await storage.getString(StorageKeys.guardianCode) ?? '').trim();
  }

  try {
    final repo = serviceLocator<StudentRepository>();
    final data = await repo.getGuardianProfile(
      schoolCode: schoolCode,
      userCode: userCode,
    );
    await _persistGuardianProfileSnapshot(
      storage: storage,
      data: data,
      userCode: userCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
    );
    return _guardianRecordCodeFromProfileMap(data);
  } catch (_) {
    return (await storage.getString(StorageKeys.guardianCode) ?? '').trim();
  }
}

/// Resolves the logged-in parent's **guardian record code** (`data.code` from
/// `GET /api/v1/guardian/profile`), not the auth `userCode`.
///
/// Priority:
/// 1) Login-context payload when it already carries an explicit guardian code
/// 2) Cached value for current user + org + school
/// 3) Fresh fetch from `/api/v1/guardian/profile` (query: schoolCode, userCode)
Future<String> resolveGuardianCodeForLoggedInUser() async {
  final storage = serviceLocator<StorageService>();

  // Persona guard: only guardian/parent users should call guardian profile API.
  final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
  if (rolesRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(rolesRaw);
      if (decoded is List) {
        final hasGuardianPersona = decoded.any((r) {
          if (r is! Map) return false;
          final role = (r['role'] ?? '').toString();
          return roleStringIsGuardianPersona(role);
        });
        if (!hasGuardianPersona) return '';
      }
    } catch (_) {
      final u = rolesRaw.toUpperCase();
      if (!u.contains('GUARDIAN') && !u.contains('PARENT')) {
        return '';
      }
    }
  }

  final loginContext = await storage.getJson(StorageKeys.loginContext);
  final fromContext = _readGuardianCodeFromLoginContext(loginContext);
  if (fromContext.isNotEmpty) {
    return fromContext;
  }

  final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
  final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
      .trim();
  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();

  if (userCode.isEmpty || schoolCode.isEmpty || organizationCode.isEmpty) {
    return '';
  }

  final cached = (await storage.getString(StorageKeys.guardianCode) ?? '')
      .trim();
  final cachedUser =
      (await storage.getString(StorageKeys.guardianCodeUser) ?? '').trim();
  final cachedSchool =
      (await storage.getString(StorageKeys.guardianCodeSchool) ?? '').trim();
  final cachedOrg =
      (await storage.getString(StorageKeys.guardianCodeOrganization) ?? '')
          .trim();

  if (cached.isNotEmpty &&
      cachedUser == userCode &&
      cachedSchool == schoolCode &&
      cachedOrg == organizationCode) {
    return cached;
  }

  try {
    final repo = serviceLocator<StudentRepository>();
    final data = await repo.getGuardianProfile(
      schoolCode: schoolCode,
      userCode: userCode,
    );
    await _persistGuardianProfileSnapshot(
      storage: storage,
      data: data,
      userCode: userCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
    );
    final code = _guardianRecordCodeFromProfileMap(data);
    if (code.isNotEmpty) return code;
  } catch (_) {
    // Caller shows a generic error; do not fall back to userCode.
  }

  return '';
}

String _readGuardianCodeFromLoginContext(Map<String, dynamic>? context) {
  if (context == null || context.isEmpty) return '';

  String pick(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = (map[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  const directKeys = <String>[
    'guardianCode',
    'GuardianCode',
    'parentCode',
    'ParentCode',
  ];
  final direct = pick(context, directKeys);
  if (direct.isNotEmpty) return direct;

  final dynamic rolesRaw = context['roles'] ?? context['Roles'];
  if (rolesRaw is List) {
    for (final role in rolesRaw) {
      if (role is! Map) continue;
      final map = Map<String, dynamic>.from(role);
      final roleName = (map['role'] ?? map['Role'] ?? '')
          .toString()
          .toUpperCase();
      if (!roleName.contains('PARENT') && !roleName.contains('GUARDIAN')) {
        continue;
      }
      final code = pick(map, directKeys);
      if (code.isNotEmpty) return code;
    }
  }

  final rawString = jsonEncode(context).toLowerCase();
  if (rawString.contains('"guardiancode"') ||
      rawString.contains('"parentcode"')) {
    final guessed = pick(context, [...directKeys.map((k) => k.toLowerCase())]);
    if (guessed.isNotEmpty) return guessed;
  }

  return '';
}
