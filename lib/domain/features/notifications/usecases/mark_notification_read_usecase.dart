import '../repositories/notification_center_repository.dart';

/// Marks a single notification as read on the backend.
class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<void> call(String id) => _repository.markAsRead(id);
}
