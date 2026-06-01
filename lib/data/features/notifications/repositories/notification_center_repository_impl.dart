import '../../../../domain/features/notifications/entities/app_notification.dart';
import '../../../../domain/features/notifications/repositories/notification_center_repository.dart';
import '../datasources/notification_center_data_source.dart';

class NotificationCenterRepositoryImpl implements NotificationCenterRepository {
  NotificationCenterRepositoryImpl(this._dataSource);

  final NotificationCenterDataSource _dataSource;

  @override
  Future<List<AppNotification>> getNotifications() =>
      _dataSource.fetchNotifications();

  @override
  Future<List<AppNotification>> markAsRead(String id) =>
      _dataSource.markAsRead(id);

  @override
  Future<List<AppNotification>> markAllAsRead() => _dataSource.markAllAsRead();
}
