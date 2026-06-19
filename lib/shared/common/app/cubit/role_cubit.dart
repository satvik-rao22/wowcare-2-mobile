import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';

class RoleState extends Equatable {
  const RoleState({
    this.role = 'admin',
    this.modulesWithRead = const <String>{},
    this.modulesWithWrite = const <String>{},
    this.granularModuleAccess = false,
  });

  final String role;
  final Set<String> modulesWithRead;
  final Set<String> modulesWithWrite;

  /// True when the matched school payload included a `permissions` list from
  /// `/users/details` (even if empty). All personas use the same read/write
  /// sets when this is on; when false, non-guardian roles keep legacy full
  /// access.
  final bool granularModuleAccess;

  RoleState copyWith({
    String? role,
    Set<String>? modulesWithRead,
    Set<String>? modulesWithWrite,
    bool? granularModuleAccess,
  }) {
    return RoleState(
      role: role ?? this.role,
      modulesWithRead: modulesWithRead ?? this.modulesWithRead,
      modulesWithWrite: modulesWithWrite ?? this.modulesWithWrite,
      granularModuleAccess: granularModuleAccess ?? this.granularModuleAccess,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    role,
    modulesWithRead,
    modulesWithWrite,
    granularModuleAccess,
  ];
}

/// Bloc replacement for the old `RoleCubit` (a `ChangeNotifier`).
///
/// Behaviour is preserved exactly; only the propagation mechanism changed from
/// `notifyListeners()` to `_safeEmit()`. Public getters/methods are kept (getters
/// delegate to [state]) so consumers switch from
/// `context.watch/read<RoleCubit>()` to the cubit with only a type rename.
///
/// MVVM golden rule: this ViewModel has no View dependency (no BuildContext,
/// widgets, navigation).
class RoleCubit extends Cubit<RoleState> {
  RoleCubit() : super(const RoleState()) {
    _bootstrap();
  }

  /// Internal control flag (non-reactive, mirrors the old `_initialized`).
  bool _initialized = false;

  String get role => state.role;
  bool get isParent => state.role == 'parent';
  bool get isAdmin => state.role == 'admin' || state.role == 'staff';
  bool get isStaff => state.role == 'staff';
  bool get hasResolvedAccess => _initialized;

  /// Whether the active school context uses API module rows for this user.
  bool get usesGranularModuleAccess => state.granularModuleAccess;

  /// Emits only while open — so an emit after `close()` (e.g. on logout
  /// teardown) never throws "emit after close".
  void _safeEmit(RoleState state) {
    if (!isClosed) emit(state);
  }

  Future<void> _bootstrap() async {
    final storage = serviceLocator<StorageService>();
    final fallbackRole = await _computeFallbackRole(storage);
    _safeEmit(state.copyWith(role: fallbackRole));
    await refreshAccessFromServer();
  }

  Future<void> setRole(String role) async {
    if (role != 'admin' && role != 'parent' && role != 'staff') {
      return;
    }
    _safeEmit(state.copyWith(role: role));
  }

  Future<void> clearRole() async {
    _safeEmit(const RoleState());
  }

  /// After logout / session expiry: drop module access memory and force a fresh
  /// `/users/details` resolution on next sign-in (storage is cleared
  /// separately).
  void resetSessionForLogout() {
    _initialized = false;
    _safeEmit(const RoleState());
  }

  bool canReadModule(String module) {
    final normalized = _normalizeModule(module);
    if (!state.granularModuleAccess) {
      if (state.modulesWithRead.isEmpty && state.modulesWithWrite.isEmpty) {
        if (isParent) return false;
        return true;
      }
    }
    return state.modulesWithRead.contains(normalized) ||
        state.modulesWithWrite.contains(normalized);
  }

  bool canWriteModule(String module) {
    final normalized = _normalizeModule(module);
    if (!state.granularModuleAccess) {
      if (state.modulesWithRead.isEmpty && state.modulesWithWrite.isEmpty) {
        if (isParent) return false;
        return true;
      }
    }
    return state.modulesWithWrite.contains(normalized);
  }

  /// Opens navigation / read-only surfaces for [module] (read or write grants
  /// access). Before granular permissions load (no API list yet), allows access
  /// so the app does not freeze; with an explicit empty permission list, access
  /// is denied.
  bool canOpenModule(String module) {
    if (!state.granularModuleAccess &&
        state.modulesWithRead.isEmpty &&
        state.modulesWithWrite.isEmpty) {
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
    final accessToken = (await storage.getString(StorageKeys.accessToken) ?? '')
        .trim();
    if (accessToken.isEmpty) {
      return;
    }

    // Try remote first. If backend returns 500 for this user, fallback
    // gracefully.
    try {
      final remote = serviceLocator<AuthRemoteDataSource>();
      final data = await remote.getUserDetails(accessToken: accessToken);
      if (data.isNotEmpty) {
        await storage.saveString(
          StorageKeys.userAccessDetails,
          jsonEncode(data),
        );
      }
      _safeEmit(await _resolveAccessState(data, storage));
      return;
    } catch (_) {}

    final fallbackRole = await _computeFallbackRole(storage);
    _safeEmit(state.copyWith(role: fallbackRole));
  }

  Future<String> _computeFallbackRole(StorageService storage) async {
    // Fallback derives role from API-provided roles only.
    final roleJson = (await storage.getString(StorageKeys.roles) ?? '')
        .toUpperCase();
    if (roleJson.contains('GUARDIAN') || roleJson.contains('PARENT')) {
      return 'parent';
    } else if (roleJson.contains('STAFF') || roleJson.contains('TEACHER')) {
      return 'staff';
    }
    return 'admin';
  }

  Future<RoleState> _resolveAccessState(
    List<Map<String, dynamic>> users,
    StorageService storage,
  ) async {
    final modulesWithRead = <String>{};
    final modulesWithWrite = <String>{};
    final org = (await storage.getString(StorageKeys.organizationCode) ?? '')
        .trim();
    final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();

    final candidates = <Map<String, dynamic>>[];
    for (final user in users) {
      if (org.isNotEmpty) {
        final userOrg = (user['organizationCode'] ?? '').toString().trim();
        if (userOrg != org) continue;
      }
      final schools = user['schools'];
      if (schools is! List) continue;
      for (final s in schools) {
        if (s is! Map) continue;
        final schoolMap = Map<String, dynamic>.from(s);
        final schoolCode = (schoolMap['schoolCode'] ?? '').toString().trim();
        if (school.isNotEmpty && schoolCode != school) continue;
        final status = (schoolMap['status'] ?? 'ACTIVE')
            .toString()
            .toUpperCase()
            .trim();
        if (status.isNotEmpty && status != 'ACTIVE') continue;
        if ((schoolMap['role'] ?? '').toString().trim().isEmpty) continue;
        candidates.add(schoolMap);
      }
    }

    if (candidates.isEmpty) {
      return RoleState(role: await _computeFallbackRole(storage));
    }

    final active = (await storage.getString(StorageKeys.activeSchoolRole) ?? '')
        .trim();
    final activeUpper = active.toUpperCase();

    Map<String, dynamic>? matchedSchool;
    if (activeUpper.isNotEmpty) {
      for (final c in candidates) {
        final r = (c['role'] ?? '').toString().trim().toUpperCase();
        if (r == activeUpper) {
          matchedSchool = c;
          break;
        }
      }
    }
    matchedSchool ??= candidates.first;

    final chosenRole = (matchedSchool['role'] ?? '').toString().trim();
    if (chosenRole.isEmpty) {
      return RoleState(role: await _computeFallbackRole(storage));
    }

    if (activeUpper.isEmpty || activeUpper != chosenRole.toUpperCase()) {
      await serviceLocator<AuthLocalDataSource>()
          .persistActiveSchoolPersonaRole(chosenRole);
    }

    String role;
    final backendRole = chosenRole.toLowerCase();
    if (backendRole.contains('guardian') || backendRole.contains('parent')) {
      role = 'parent';
    } else if (backendRole.contains('staff') ||
        backendRole.contains('teacher')) {
      role = 'staff';
    } else {
      role = 'admin';
    }

    bool granularModuleAccess = false;
    final permissions = matchedSchool['permissions'];
    if (permissions is List) {
      granularModuleAccess = true;
      for (final p in permissions) {
        if (p is! Map) continue;
        final permissionMap = Map<String, dynamic>.from(p);
        final module = _normalizeModule(
          (permissionMap['module'] ?? '').toString(),
        );
        if (module.isEmpty) continue;
        if (permissionMap['read'] == true) {
          modulesWithRead.add(module);
        }
        if (permissionMap['write'] == true) {
          modulesWithWrite.add(module);
        }
      }
    }

    return RoleState(
      role: role,
      modulesWithRead: modulesWithRead,
      modulesWithWrite: modulesWithWrite,
      granularModuleAccess: granularModuleAccess,
    );
  }

  /// Aligns UI aliases (e.g. `staff-attendance`) with backend keys
  /// (`STAFF_ATTENDANCE`).
  String _normalizeModule(String module) =>
      module.trim().toLowerCase().replaceAll('-', '_');
}
