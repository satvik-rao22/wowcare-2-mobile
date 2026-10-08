import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/auth/kiosk_access_control.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/observability/telemetry.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';

class RoleState extends Equatable {
  const RoleState({
    this.role = 'admin',
    this.modulesWithRead = const <String>{},
    this.modulesWithWrite = const <String>{},
    this.granularModuleAccess = false,
    this.activeSchoolRoleRaw = '',
    this.personaResolved = false,
  });

  /// The coarse persona bucket: `admin`, `staff`, `parent` or `kiosk`.
  ///
  /// **Defaults to `admin`, the most privileged value.** That default is load
  /// bearing for existing callers (a transient `/users/details` failure must
  /// not demote a signed-in admin), so it is deliberately unchanged — but it
  /// means anything DISPATCHING on persona must check [personaResolved] first
  /// or it silently renders the admin branch for an unresolved user. See
  /// `DashboardScreen`.
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

  /// True once a persona has actually been **emitted** — either from
  /// [RoleCubit._bootstrap]'s storage-derived fallback or from a
  /// `/users/details` resolution.
  ///
  /// Distinct from [RoleCubit.hasResolvedAccess], which flips as soon as the
  /// server refresh *starts* and so cannot be used to decide whether [role] is
  /// trustworthy yet. Reset to false by `const RoleState()`, which is what
  /// [RoleCubit.clearRole] and [RoleCubit.resetSessionForLogout] emit — so a
  /// logout correctly returns to "unresolved" rather than to "admin".
  ///
  /// Additive: no existing getter or caller changes behaviour because of it.
  final bool personaResolved;

  RoleState copyWith({
    String? role,
    Set<String>? modulesWithRead,
    Set<String>? modulesWithWrite,
    bool? granularModuleAccess,
    String? activeSchoolRoleRaw,
    bool? personaResolved,
  }) {
    return RoleState(
      role: role ?? this.role,
      modulesWithRead: modulesWithRead ?? this.modulesWithRead,
      modulesWithWrite: modulesWithWrite ?? this.modulesWithWrite,
      granularModuleAccess: granularModuleAccess ?? this.granularModuleAccess,
      activeSchoolRoleRaw: activeSchoolRoleRaw ?? this.activeSchoolRoleRaw,
      personaResolved: personaResolved ?? this.personaResolved,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    role,
    modulesWithRead,
    modulesWithWrite,
    granularModuleAccess,
    activeSchoolRoleRaw,
    personaResolved,
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
    SchoolSwitchEvents.epoch.addListener(_onSchoolSwitched);
    _bootstrap();
  }

  @override
  void onChange(Change<RoleState> change) {
    super.onChange(change);
    unawaited(_syncTelemetrySession());
  }

  @override
  Future<void> close() {
    SchoolSwitchEvents.epoch.removeListener(_onSchoolSwitched);
    return super.close();
  }

  // A switch can leave the state unchanged (same persona and permissions in
  // the new school), so it does not always reach [onChange].
  void _onSchoolSwitched() => unawaited(_syncTelemetrySession());

  /// Labels Sentry and Crashlytics reports with the signed-in user code and
  /// where the user is. Every persona change passes through here, which covers
  /// cold start, login, logout and session expiry. Codes only, never a name.
  Future<void> _syncTelemetrySession() async {
    // A debug build reports nowhere unless Sentry is forced on.
    if (kDebugMode && !Telemetry.isEnabled) return;
    try {
      final storage = serviceLocator<StorageService>();
      final userCode =
          (await storage.getString(StorageKeys.userCode) ?? '').trim();
      if (!state.personaResolved || userCode.isEmpty) {
        AppLogger.setUserIdentifier('');
        await Telemetry.clearSession();
        return;
      }
      AppLogger.setUserIdentifier(userCode);
      await Telemetry.setSession(
        userCode: userCode,
        persona: state.role,
        organizationCode:
            (await storage.getString(StorageKeys.organizationCode) ?? '')
                .trim(),
        schoolCode: (await storage.getString(StorageKeys.schoolCode) ?? '')
            .trim(),
        kiosk: serviceLocator.isRegistered<KioskAccessControl>() &&
            await serviceLocator<KioskAccessControl>().isKioskModeActive(),
      );
    } catch (_) {
      // Labels are best effort and must never disturb the session.
    }
  }

  /// Internal control flag (non-reactive, mirrors the old `_initialized`).
  bool _initialized = false;

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

  /// Whether [role] can be trusted to dispatch on yet.
  ///
  /// [hasResolvedAccess] flips when the server refresh *starts*; this one flips
  /// only once a persona has actually been emitted. Screens that pick a widget
  /// per persona must check this, because [RoleState.role] defaults to `admin`.
  bool get isPersonaResolved => state.personaResolved;

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
    _safeEmit(state.copyWith(role: fallbackRole, personaResolved: true));
    await refreshAccessFromServer();
  }

  Future<void> setRole(String role) async {
    if (role != 'admin' && role != 'parent' && role != 'staff') {
      return;
    }
    _safeEmit(state.copyWith(role: role, personaResolved: true));
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
    final accessToken = await TokenRefreshService.instance.readAccessToken();
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
      _safeEmit(
        (await _resolveAccessState(data, storage))
            .copyWith(personaResolved: true),
      );
      return;
    } catch (_) {}

    // `/users/details` failed (offline / 5xx). Keep the persona we already
    // resolved rather than recomputing — re-deriving here previously flipped a
    // signed-in admin who is ALSO a guardian over to the guardian UI on a
    // transient error, since the fallback has no permissions payload to match.
    if (state.granularModuleAccess) return;

    final fallbackRole = await _computeFallbackRole(storage);
    _safeEmit(state.copyWith(role: fallbackRole, personaResolved: true));
  }

  /// Delegates to [resolvePersonaFamilyFromStorage] — the same rule is needed by
  /// the cold-start notification tap handler, which runs during bootstrap with
  /// no widget tree (and so no RoleCubit) to ask. Keeping one implementation is
  /// what guarantees a cold-start deep link routes where a warm one does.
  Future<String> _computeFallbackRole(StorageService storage) =>
      resolvePersonaFamilyFromStorage(storage);

  Future<RoleState> _resolveAccessState(
    List<Map<String, dynamic>> users,
    StorageService storage,
  ) async {
    final modulesWithRead = <String>{};
    final modulesWithWrite = <String>{};
    final org =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();

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
        final status =
            (schoolMap['status'] ?? 'ACTIVE').toString().toUpperCase().trim();
        if (status.isNotEmpty && status != 'ACTIVE') continue;
        if ((schoolMap['role'] ?? '').toString().trim().isEmpty) continue;
        candidates.add(schoolMap);
      }
    }

    if (candidates.isEmpty) {
      return RoleState(role: await _computeFallbackRole(storage));
    }

    final active =
        (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
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
        final module =
            _normalizeModule((permissionMap['module'] ?? '').toString());
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
