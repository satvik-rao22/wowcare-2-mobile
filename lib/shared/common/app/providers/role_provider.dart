import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';

class RoleProvider extends ChangeNotifier {
  String _role = 'admin'; // Default to admin
  final Set<String> _modulesWithRead = <String>{};
  final Set<String> _modulesWithWrite = <String>{};
  /// True when the matched school payload included a `permissions` list from
  /// `/users/details` (even if empty). All personas use the same read/write
  /// sets when this is on; when false, non-guardian roles keep legacy full access.
  bool _granularModuleAccess = false;
  bool _initialized = false;

  RoleProvider() {
    _bootstrap();
  }

  String get role => _role;
  bool get isParent => _role == 'parent';
  bool get isAdmin => _role == 'admin' || _role == 'staff';
  bool get isStaff => _role == 'staff';
  bool get hasResolvedAccess => _initialized;

  Future<void> _bootstrap() async {
    await _fallbackFromRole(serviceLocator<StorageService>());
    await refreshAccessFromServer();
  }

  Future<void> setRole(String role) async {
    if (role != 'admin' && role != 'parent' && role != 'staff') {
      return;
    }
    _role = role;
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = 'admin';
    _modulesWithRead.clear();
    _modulesWithWrite.clear();
    _granularModuleAccess = false;
    notifyListeners();
  }

  /// Whether the active school context uses API module rows for this user.
  bool get usesGranularModuleAccess => _granularModuleAccess;

  bool canReadModule(String module) {
    final normalized = _normalizeModule(module);
    if (!_granularModuleAccess) {
      if (_modulesWithRead.isEmpty && _modulesWithWrite.isEmpty) {
        if (isParent) return false;
        return true;
      }
    }
    return _modulesWithRead.contains(normalized) ||
        _modulesWithWrite.contains(normalized);
  }

  bool canWriteModule(String module) {
    final normalized = _normalizeModule(module);
    if (!_granularModuleAccess) {
      if (_modulesWithRead.isEmpty && _modulesWithWrite.isEmpty) {
        if (isParent) return false;
        return true;
      }
    }
    return _modulesWithWrite.contains(normalized);
  }

  /// Opens navigation / read-only surfaces for [module] (read or write grants access).
  /// Before granular permissions load (no API list yet), allows access so the app
  /// does not freeze; with an explicit empty permission list, access is denied.
  bool canOpenModule(String module) {
    if (!_granularModuleAccess &&
        _modulesWithRead.isEmpty &&
        _modulesWithWrite.isEmpty) {
      return true;
    }
    return canReadModule(module);
  }

  bool canAccessAny(List<String> modules) {
    for (final module in modules) {
      if (canReadModule(module)) return true;
    }
    return false;
  }

  Future<void> refreshAccessFromServer({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    final storage = serviceLocator<StorageService>();
    final accessToken = (await storage.getString(StorageKeys.accessToken) ?? '').trim();
    if (accessToken.isEmpty) {
      notifyListeners();
      return;
    }

    // Try remote first. If backend returns 500 for this user, fallback gracefully.
    try {
      final remote = serviceLocator<AuthRemoteDataSource>();
      final data = await remote.getUserDetails(accessToken: accessToken);
      if (data.isNotEmpty) {
        await storage.saveString(StorageKeys.userAccessDetails, jsonEncode(data));
      }
      await _applyAccessPayload(data, storage);
      notifyListeners();
      return;
    } catch (_) {}

    await _fallbackFromRole(storage);
    notifyListeners();
  }

  Future<void> _fallbackFromRole(StorageService storage) async {
    // Fallback derives role from API-provided roles only.
    final roleJson = (await storage.getString(StorageKeys.roles) ?? '').toUpperCase();
    if (roleJson.contains('GUARDIAN') || roleJson.contains('PARENT')) {
      _role = 'parent';
    } else if (roleJson.contains('STAFF') || roleJson.contains('TEACHER')) {
      _role = 'staff';
    } else {
      _role = 'admin';
    }
  }

  Future<void> _applyAccessPayload(
    List<Map<String, dynamic>> users,
    StorageService storage,
  ) async {
    _modulesWithRead.clear();
    _modulesWithWrite.clear();
    _granularModuleAccess = false;
    final org = (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();

    Map<String, dynamic>? matchedSchool;
    for (final user in users) {
      final schools = user['schools'];
      if (schools is! List) continue;
      for (final s in schools) {
        if (s is! Map) continue;
        final schoolMap = Map<String, dynamic>.from(s);
        final schoolCode = (schoolMap['schoolCode'] ?? '').toString().trim();
        if (school.isNotEmpty && schoolCode != school) continue;
        if (org.isNotEmpty) {
          final userOrg = (user['organizationCode'] ?? '').toString().trim();
          if (userOrg != org) continue;
        }
        matchedSchool = schoolMap;
        break;
      }
      if (matchedSchool != null) break;
    }

    if (matchedSchool == null) {
      await _fallbackFromRole(storage);
      return;
    }

    final backendRole = (matchedSchool['role'] ?? '').toString().toLowerCase();
    if (backendRole.contains('guardian') || backendRole.contains('parent')) {
      _role = 'parent';
    } else if (backendRole.contains('staff') || backendRole.contains('teacher')) {
      _role = 'staff';
    } else {
      _role = 'admin';
    }

    final permissions = matchedSchool['permissions'];
    if (permissions is List) {
      _granularModuleAccess = true;
      for (final p in permissions) {
        if (p is! Map) continue;
        final permissionMap = Map<String, dynamic>.from(p);
        final module = _normalizeModule((permissionMap['module'] ?? '').toString());
        if (module.isEmpty) continue;
        if (permissionMap['read'] == true) {
          _modulesWithRead.add(module);
        }
        if (permissionMap['write'] == true) {
          _modulesWithWrite.add(module);
        }
      }
    }
  }

  /// Aligns UI aliases (e.g. `staff-attendance`) with backend keys (`STAFF_ATTENDANCE`).
  String _normalizeModule(String module) =>
      module.trim().toLowerCase().replaceAll('-', '_');
}
