import '../entities/app_notification.dart';
import '../repositories/notification_center_repository.dart';

/// Marks a single notification as read and returns the updated list.
class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<List<AppNotification>> call(String id) => _repository.markAsRead(id);
}
