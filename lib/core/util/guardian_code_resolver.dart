import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

/// Resolves the logged-in parent's **guardian record code** (`data.code` from
/// `GET /api/v1/guardian/profile`), not the auth `userCode`.
///
/// Priority:
/// 1) Login-context payload when it already carries an explicit guardian code
/// 2) Cached value for current user + org + school
/// 3) Fresh fetch from `/api/v1/guardian/profile` (query: schoolCode, userCode)
Future<String> resolveGuardianCodeForLoggedInUser() async {
  final storage = serviceLocator<StorageService>();

  final loginContext = await storage.getJson(StorageKeys.loginContext);
  final fromContext = _readGuardianCodeFromLoginContext(loginContext);
  if (fromContext.isNotEmpty) {
    return fromContext;
  }

  final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
  final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
  final organizationCode =
      (await storage.getString(StorageKeys.organizationCode) ?? '').trim();

  if (userCode.isEmpty || schoolCode.isEmpty || organizationCode.isEmpty) {
    return '';
  }

  final cached = (await storage.getString(StorageKeys.guardianCode) ?? '').trim();
  final cachedUser =
      (await storage.getString(StorageKeys.guardianCodeUser) ?? '').trim();
  final cachedSchool =
      (await storage.getString(StorageKeys.guardianCodeSchool) ?? '').trim();
  final cachedOrg =
      (await storage.getString(StorageKeys.guardianCodeOrganization) ?? '').trim();

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
    final code = (data['code'] ?? '').toString().trim();
    if (code.isNotEmpty) {
      await storage.saveString(StorageKeys.guardianCode, code);
      await storage.saveString(StorageKeys.guardianCodeUser, userCode);
      await storage.saveString(StorageKeys.guardianCodeSchool, schoolCode);
      await storage.saveString(
        StorageKeys.guardianCodeOrganization,
        organizationCode,
      );
      return code;
    }
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
      final roleName =
          (map['role'] ?? map['Role'] ?? '').toString().toUpperCase();
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
