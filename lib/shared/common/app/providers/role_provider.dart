import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleProvider extends ChangeNotifier {
  static const String _roleKey = 'selected_role';
  String _role = 'admin'; // Default to admin
  final Set<String> _modulesWithRead = <String>{};
  final Set<String> _modulesWithWrite = <String>{};
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
    await _loadRole();
    await refreshAccessFromServer();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString(_roleKey) ?? 'admin';
    notifyListeners();
  }

  Future<void> setRole(String role) async {
    if (role != 'admin' && role != 'parent' && role != 'staff') {
      return;
    }
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = 'admin';
    _modulesWithRead.clear();
    _modulesWithWrite.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }

  bool canReadModule(String module) {
    if (_modulesWithRead.isEmpty && _modulesWithWrite.isEmpty) {
      // Keep old behavior while details are unavailable.
      if (isParent) return false;
      return true;
    }
    final normalized = _normalizeModule(module);
    return _modulesWithRead.contains(normalized) ||
        _modulesWithWrite.contains(normalized);
  }

  bool canWriteModule(String module) {
    final normalized = _normalizeModule(module);
    return _modulesWithWrite.contains(normalized);
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
    final prefs = await SharedPreferences.getInstance();
    final stored = (prefs.getString(_roleKey) ?? '').toLowerCase().trim();
    if (stored == 'parent' || stored == 'staff' || stored == 'admin') {
      _role = stored;
      return;
    }

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

  String _normalizeModule(String module) => module.trim().toLowerCase();
}
