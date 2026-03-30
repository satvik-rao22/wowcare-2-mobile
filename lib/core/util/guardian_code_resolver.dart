import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// Best-effort resolver for logged-in parent/guardian code.
///
/// Priority:
/// 1) login-context payload keys (when backend provides explicit guardian code)
/// 2) userCode from auth token payload (common parent identity key)
Future<String> resolveGuardianCodeForLoggedInUser() async {
  final storage = serviceLocator<StorageService>();

  final loginContext = await storage.getJson(StorageKeys.loginContext);
  final fromContext = _readGuardianCodeFromLoginContext(loginContext);
  if (fromContext.isNotEmpty) {
    return fromContext;
  }

  return (await storage.getString(StorageKeys.userCode) ?? '').trim();
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
      final roleName = (map['role'] ?? map['Role'] ?? '').toString().toUpperCase();
      if (!roleName.contains('PARENT') && !roleName.contains('GUARDIAN')) continue;
      final code = pick(map, directKeys);
      if (code.isNotEmpty) return code;
    }
  }

  final rawString = jsonEncode(context).toLowerCase();
  if (rawString.contains('"guardiancode"') || rawString.contains('"parentcode"')) {
    final guessed = pick(context, [...directKeys.map((k) => k.toLowerCase())]);
    if (guessed.isNotEmpty) return guessed;
  }

  return '';
}
