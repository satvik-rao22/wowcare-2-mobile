import '../repositories/notification_center_repository.dart';

/// Fetches one page of the notification-center list (newest first).
class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<NotificationPage> call({
    int page = 0,
    int size = 10,
    String? module,
    bool onlyUnread = false,
  }) => _repository.getNotifications(
    page: page,
    size: size,
    module: module,
    onlyUnread: onlyUnread,
  );
}
