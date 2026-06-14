import '../entities/app_notification.dart';
import '../repositories/notification_center_repository.dart';

/// Fetches the notification-center list (newest first).
class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<List<AppNotification>> call() => _repository.getNotifications();
}
