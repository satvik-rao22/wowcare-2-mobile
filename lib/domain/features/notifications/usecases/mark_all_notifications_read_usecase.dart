import '../entities/app_notification.dart';
import '../repositories/notification_center_repository.dart';

/// Marks every notification as read and returns the updated list.
class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<List<AppNotification>> call() => _repository.markAllAsRead();
}
