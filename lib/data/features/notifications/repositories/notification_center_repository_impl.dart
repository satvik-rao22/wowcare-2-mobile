import '../../../../domain/features/notifications/repositories/notification_center_repository.dart';
import '../datasources/notification_center_data_source.dart';

class NotificationCenterRepositoryImpl implements NotificationCenterRepository {
  NotificationCenterRepositoryImpl(this._dataSource);

  final NotificationCenterDataSource _dataSource;

  @override
  Future<NotificationPage> getNotifications({
    int page = 0,
    int size = 10,
    String? module,
    bool onlyUnread = false,
  }) async {
    final result = await _dataSource.fetchNotifications(
      page: page,
      size: size,
      module: module,
      onlyUnread: onlyUnread,
    );
    return (items: result.items, hasMore: result.hasMore);
  }

  @override
  Future<void> markAsRead(String id) => _dataSource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();

  @override
  Future<({int unread, int unclicked})> getUnreadCounts() =>
      _dataSource.getUnreadCounts();
}
