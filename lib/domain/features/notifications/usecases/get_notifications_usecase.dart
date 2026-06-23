import '../repositories/notification_center_repository.dart';

/// Fetches one page of the notification-center list (newest first).
class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<NotificationPage> call({int page = 0, int size = 10}) =>
      _repository.getNotifications(page: page, size: size);
}
