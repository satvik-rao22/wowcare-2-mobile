import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
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
    final role = _normalizeRole(
      (await _storage.getString(StorageKeys.activeSchoolRole) ?? '').trim(),
    );
    return (
      userCode: userCode,
      schoolCode: schoolCode.isEmpty ? null : schoolCode,
      role: role.isEmpty ? null : role,
    );
  }

  /// Collapses backend role codes (SCHOOL_ADMIN, ORGANIZATION_ADMIN, TEACHER…)
  /// into the ADMIN | STAFF | GUARDIAN enum the notification service expects
  /// (same mapping used by FCM registration and preferences). Empty stays empty
  /// so the param is simply omitted when no role is stored.
  String _normalizeRole(String raw) {
    final r = raw.trim().toUpperCase();
    if (r.isEmpty) return '';
    if (r.contains('GUARDIAN') || r.contains('PARENT')) return 'GUARDIAN';
    if (r.contains('ADMIN')) return 'ADMIN';
    return 'STAFF';
  }
}
