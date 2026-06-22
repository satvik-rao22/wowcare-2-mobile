import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import 'notification_center_data_source.dart';
import 'notification_logs_remote_data_source.dart';

/// REST-backed notification center (bell list + read/click).
class NotificationCenterRemoteDataSource implements NotificationCenterDataSource {
  NotificationCenterRemoteDataSource({
    required NotificationLogsRemoteDataSource logsRemote,
    required StorageService storage,
  })  : _logsRemote = logsRemote,
        _storage = storage;

  final NotificationLogsRemoteDataSource _logsRemote;
  final StorageService _storage;

  @override
  Future<NotificationCenterPage> fetchNotifications({
    int page = 0,
    int size = 10,
  }) async {
    final userCode =
        (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    if (userCode.isEmpty) {
      throw Exception('User not signed in');
    }
    final schoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final result = await _logsRemote.fetchLogs(
      userCode: userCode,
      schoolCode: schoolCode.isEmpty ? null : schoolCode,
      page: page,
      size: size,
    );
    return (items: result.items, hasMore: result.hasMore);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _logsRemote.markRead(id);
    try {
      await _logsRemote.trackClick(id);
    } catch (_) {
      // Click analytics are best-effort; read state is what matters for UX.
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final userCode =
        (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    if (userCode.isEmpty) {
      throw Exception('User not signed in');
    }
    await _logsRemote.markAllRead(userCode);
  }
}
