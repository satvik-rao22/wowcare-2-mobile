import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/user_details_school_roles.dart';
import 'notification_center_data_source.dart';
import 'notification_inbox_remote_data_source.dart';

/// REST-backed notification center (bell list + read/click + unread counts),
/// talking to the `/api/v1/notification/inbox` endpoints.
class NotificationCenterRemoteDataSource implements NotificationCenterDataSource {
  NotificationCenterRemoteDataSource({
    required NotificationInboxRemoteDataSource inboxRemote,
    required StorageService storage,
  })  : _inboxRemote = inboxRemote,
        _storage = storage;

  final NotificationInboxRemoteDataSource _inboxRemote;
  final StorageService _storage;

  @override
  Future<NotificationCenterPage> fetchNotifications({
    int page = 0,
    int size = 10,
    String? module,
    bool onlyUnread = false,
  }) async {
    final ctx = await _context();
    final result = await _inboxRemote.fetchInbox(
      userCode: ctx.userCode,
      schoolCode: ctx.schoolCode,
      role: ctx.role,
      module: module,
      onlyShowUnread: onlyUnread,
      page: page,
      size: size,
    );
    return (items: result.items, hasMore: result.hasMore);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _inboxRemote.markRead(id);
    try {
      await _inboxRemote.trackClick(id);
    } catch (_) {
      // Click analytics are best-effort; read state is what matters for UX.
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final ctx = await _context();
    await _inboxRemote.markAllRead(
      userCode: ctx.userCode,
      schoolCode: ctx.schoolCode,
      role: ctx.role,
    );
  }

  @override
  Future<({int unread, int unclicked})> getUnreadCounts() async {
    final ctx = await _context();
    return _inboxRemote.fetchUnreadCounts(
      userCode: ctx.userCode,
      schoolCode: ctx.schoolCode,
      role: ctx.role,
    );
  }

  /// Resolves the signed-in user context the inbox endpoints are scoped to.
  Future<({String userCode, String? schoolCode, String? role})>
      _context() async {
    final userCode =
        (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    if (userCode.isEmpty) {
      throw Exception('User not signed in');
    }
    final schoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final role = await _resolveRole(schoolCode);
    return (
      userCode: userCode,
      schoolCode: schoolCode.isEmpty ? null : schoolCode,
      role: role.isEmpty ? null : role,
    );
  }

  /// Exact backend role (e.g. `ORGANIZATION_ADMIN`, `SCHOOL_ADMIN`, `TEACHER`,
  /// `GUARDIAN`) for the active org+school, sourced from the cached
  /// `GET /users/details` snapshot (the same data [RoleCubit] resolves at
  /// login/refresh). Sends the user's actual role as-is rather than collapsing
  /// it into a generic ADMIN/STAFF/GUARDIAN bucket, so the inbox reflects the
  /// role currently logged in. Falls back to the raw `activeSchoolRole` string
  /// when there's no cached user-details snapshot yet.
  Future<String> _resolveRole(String schoolCode) async {
    final activeStored =
        (await _storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();

    if (organizationCode.isNotEmpty && schoolCode.isNotEmpty) {
      final users = await readCachedUserAccessDetailsUsers(_storage);
      final distinctRoles = distinctActiveRolesForCurrentSchoolFromUserDetails(
        users,
        organizationCode,
        schoolCode,
      );
      if (distinctRoles.isNotEmpty) {
        final activeUpper = activeStored.toUpperCase();
        // 1. Exact backend-role match (keeps ORGANIZATION_ADMIN vs
        //    SCHOOL_ADMIN distinct).
        for (final r in distinctRoles) {
          if (r.trim().toUpperCase() == activeUpper) return r.trim();
        }
        // 2. Persona-family match — tolerates stored aliases (e.g. 'PARENT'
        //    for 'GUARDIAN', 'ADMIN' for 'SCHOOL_ADMIN') so a format drift in
        //    activeSchoolRole never silently falls through to the wrong
        //    role, mirroring RoleCubit's own active-persona resolution.
        if (activeUpper.isNotEmpty) {
          final wantFamily = _personaFamily(activeStored);
          for (final r in distinctRoles) {
            if (_personaFamily(r) == wantFamily) return r.trim();
          }
        }
        // 3. No active persona resolved for this dual/multi-role account: an
        //    arbitrary (array-order) pick can send a role the backend
        //    session doesn't recognize and 401. Only auto-pick when there's
        //    just one possible role for this school; otherwise omit the
        //    param rather than guess wrong.
        if (distinctRoles.length == 1) return distinctRoles.first.trim();
        return '';
      }
    }

    return activeStored;
  }

  /// Coarse persona bucket for a raw backend role string. Mirrors
  /// `RoleCubit._personaFamily` — kept local since that one is private and
  /// this data source has no BuildContext to read the cubit directly.
  String _personaFamily(String backendRole) {
    final r = backendRole.trim().toLowerCase();
    if (r.contains('kiosk')) return 'kiosk';
    if (r.contains('guardian') || r.contains('parent')) return 'parent';
    if (r.contains('staff') || r.contains('teacher')) return 'staff';
    return 'admin';
  }
}
