import '../../../../domain/features/notifications/repositories/notification_center_repository.dart';
import '../datasources/notification_center_data_source.dart';

class NotificationCenterRepositoryImpl implements NotificationCenterRepository {
  NotificationCenterRepositoryImpl(this._dataSource);

  final NotificationCenterDataSource _dataSource;

  @override
  Future<NotificationPage> getNotifications({int page = 0, int size = 10}) async {
    final result =
        await _dataSource.fetchNotifications(page: page, size: size);
    return (items: result.items, hasMore: result.hasMore);
  }

  @override
  Future<void> markAsRead(String id) => _dataSource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();
}
