import '../repositories/notification_center_repository.dart';

/// Marks every notification as read on the backend.
class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<void> call() => _repository.markAllAsRead();
}
