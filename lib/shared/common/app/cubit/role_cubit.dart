import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/core/util/login_persona_util.dart';

class RoleState extends Equatable {
  const RoleState({
    this.role = 'admin',
    this.modulesWithRead = const <String>{},
    this.modulesWithWrite = const <String>{},
    this.granularModuleAccess = false,
    this.activeSchoolRoleRaw = '',
  });

  final String role;
  final Set<String> modulesWithRead;
  final Set<String> modulesWithWrite;

  /// True when the matched school payload included a `permissions` list from
  /// `/users/details` (even if empty). All personas use the same read/write
  /// sets when this is on; when false, non-guardian roles keep legacy full
  /// access.
  final bool granularModuleAccess;

  /// The raw backend role string for the matched school entry (e.g.
  /// `ORGANIZATION_ADMIN`, `SCHOOL_ADMIN`, `STAFF`) before it's collapsed into
  /// [role]'s coarse persona bucket. Additive — [role] remains the source of
  /// truth for all existing staff/admin/parent/kiosk gating; this only backs
  /// finer-grained getters like [RoleCubit.isOrganizationAdmin].
  final String activeSchoolRoleRaw;

  RoleState copyWith({
    String? role,
    Set<String>? modulesWithRead,
    Set<String>? modulesWithWrite,
    bool? granularModuleAccess,
    String? activeSchoolRoleRaw,
  }) {
    return RoleState(
      role: role ?? this.role,
      modulesWithRead: modulesWithRead ?? this.modulesWithRead,
      modulesWithWrite: modulesWithWrite ?? this.modulesWithWrite,
      granularModuleAccess: granularModuleAccess ?? this.granularModuleAccess,
      activeSchoolRoleRaw: activeSchoolRoleRaw ?? this.activeSchoolRoleRaw,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    role,
    modulesWithRead,
    modulesWithWrite,
    granularModuleAccess,
    activeSchoolRoleRaw,
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
    unawaited(_bootstrap());
  }

  /// Internal control flag (non-reactive, mirrors the old `_initialized`).
  bool _initialized = false;

  /// In-flight `/users/details` fetch. Concurrent callers (constructor
  /// bootstrap, splash, sign-in — the forced ones bypass [_initialized])
  /// join this future instead of each firing their own request.
  Future<void>? _inFlightRefresh;

  /// Completion time of the last successful `/users/details` fetch. A
  /// forced refresh landing within [_refreshFreshness] of it is a startup
  /// duplicate, not a real context change, and is skipped.
  DateTime? _lastFetchedAt;

  /// School/persona switches (the legitimate force-refresh triggers) happen
  /// seconds-to-minutes apart, far outside this window.
  static const Duration _refreshFreshness = Duration(seconds: 3);

  String get role => state.role;
  bool get isParent => state.role == 'parent';
  /// Alias for [isParent] — guardian and parent are the same persona bucket.
  bool get isGuardian => isParent;
  bool get isAdmin => state.role == 'admin' || state.role == 'staff';
  bool get isStaff => state.role == 'staff';
  /// True only for the ADMIN persona (director/principal/school-admin/
  /// org-admin), unlike [isAdmin] which also covers the STAFF (teacher)
  /// persona. Use this where a permission must be admin-only, e.g. staff
  /// attendance override sign-in for an absent staff member.
  bool get isTrueAdmin => state.role == 'admin';
  bool get isKiosk => state.role == 'kiosk';
  /// True specifically for the `ORGANIZATION_ADMIN` backend role. Does not
  /// change [isAdmin] (still true for org admins, as before) — this is an
  /// additive, finer-grained check for callers that need to distinguish
  /// organization-level admins from school-level admins.
  bool get isOrganizationAdmin =>
      state.activeSchoolRoleRaw.toUpperCase().contains('ORGANIZATION');
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
    _lastFetchedAt = null;
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

  Future<void> refreshAccessFromServer({bool force = false}) {
    if (_initialized && !force) return Future.value();

    // Forced refresh right after a fresh fetch: the constructor bootstrap
    // and the splash/sign-in forced calls all fire within app startup —
    // reuse the just-fetched data instead of hitting /users/details again.
    final lastFetch = _lastFetchedAt;
    if (force &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _refreshFreshness) {
      return Future.value();
    }

    // Concurrent invocations share one request.
    var pending = _inFlightRefresh;
    if (pending == null) {
      pending = _fetchAndResolveAccess()
          .whenComplete(() => _inFlightRefresh = null);
      _inFlightRefresh = pending;
    }
    return pending;
  }

  Future<void> _fetchAndResolveAccess() async {
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
      _lastFetchedAt = DateTime.now();
      if (data.isNotEmpty) {
        await storage.saveString(
          StorageKeys.userAccessDetails,
          jsonEncode(data),
        );
      }
      _safeEmit(await _resolveAccessState(data, storage));
      return;
    } catch (_) {}

    // `/users/details` failed (offline / 5xx). Keep the persona we already
    // resolved rather than recomputing — re-deriving here previously flipped a
    // signed-in admin who is ALSO a guardian over to the guardian UI on a
    // transient error, since the fallback has no permissions payload to match.
    if (state.granularModuleAccess) return;

    final fallbackRole = await _computeFallbackRole(storage);
    _safeEmit(state.copyWith(role: fallbackRole));
  }

  Future<String> _computeFallbackRole(StorageService storage) async {
    // The persona the user is ACTUALLY in wins. Only guess when no active
    // persona has been resolved/persisted yet (e.g. right after a fresh
    // login, since logout clears activeSchoolRole).
    final active =
        (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
    if (active.isNotEmpty) return _personaFamily(active);

    // A multi-persona account should reopen on the persona it was last
    // active as (durable across logout), not always admin/staff. Falls
    // through when there's no record for THIS account (fresh install, first
    // login, or a different user on a shared device) or that persona no
    // longer applies.
    final lastUsedRaw =
        await storage.getString(StorageKeys.lastUsedPersonaRole) ?? '';
    final currentUserCode =
        (await storage.getString(StorageKeys.userCode) ?? '').trim();
    final roleJson = await storage.getString(StorageKeys.roles) ?? '';
    final lastUsed = lastUsedPersonaFamily(
      lastUsedPersonaRoleJson: lastUsedRaw,
      currentUserCode: currentUserCode,
      currentRolesJson: roleJson,
    );
    if (lastUsed != null) return lastUsed;

    // Edge-case fallback: derive from API-provided roles only. A dual-role
    // account (e.g. SCHOOL_ADMIN + GUARDIAN) must default to the admin/staff
    // persona rather than being silently downgraded to parent — see
    // [derivePersonaFamilyFromRolesJson] for the priority order.
    return derivePersonaFamilyFromRolesJson(roleJson);
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

    // Pick the school entry whose `role` matches the persona the user is
    // actually in. A multi-role account (e.g. SCHOOL_ADMIN + GUARDIAN in the
    // same school) has one entry — with its own permissions — per role, so the
    // wrong choice here applies the wrong module ACL.
    Map<String, dynamic>? matchedSchool;
    if (activeUpper.isNotEmpty) {
      // 1. Exact backend-role match (keeps ORG_ADMIN vs SCHOOL_ADMIN distinct).
      for (final c in candidates) {
        final r = (c['role'] ?? '').toString().trim().toUpperCase();
        if (r == activeUpper) {
          matchedSchool = c;
          break;
        }
      }
      // 2. Persona-family match — tolerates stored aliases such as 'PARENT'
      //    for 'GUARDIAN' or 'ADMIN' for 'SCHOOL_ADMIN' so a format drift in
      //    activeSchoolRole never silently falls through to the wrong role.
      if (matchedSchool == null) {
        final wantFamily = _personaFamily(active);
        for (final c in candidates) {
          if (_personaFamily((c['role'] ?? '').toString()) == wantFamily) {
            matchedSchool = c;
            break;
          }
        }
      }
    }
    // 3. No active persona resolved yet: fall back to the persona derived from
    //    the login `roles` (least-privilege guardian when ambiguous) instead of
    //    blindly taking whichever role the backend listed first.
    if (matchedSchool == null) {
      final wantFamily = await _computeFallbackRole(storage);
      for (final c in candidates) {
        if (_personaFamily((c['role'] ?? '').toString()) == wantFamily) {
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

    final role = _personaFamily(chosenRole);

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
      activeSchoolRoleRaw: chosenRole,
    );
  }

  /// Collapses any backend role string to the coarse persona the UI gates on:
  /// `kiosk` / `parent` / `staff` / `admin`. Used both to choose the matching
  /// `/users/details` school entry and to set [RoleState.role], so the persona
  /// and its module ACL always come from the same entry.
  String _personaFamily(String backendRole) {
    final r = backendRole.trim().toLowerCase();
    if (r.contains('kiosk')) return 'kiosk';
    if (r.contains('guardian') || r.contains('parent')) return 'parent';
    if (r.contains('staff') || r.contains('teacher')) return 'staff';
    return 'admin';
  }

  /// Aligns UI aliases (e.g. `staff-attendance`) with backend keys
  /// (`STAFF_ATTENDANCE`).
  String _normalizeModule(String module) =>
      module.trim().toLowerCase().replaceAll('-', '_');
}
