import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/notification_center_repository.dart';

/// Marks every notification as read on the backend.
class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final NotificationCenterRepository _repository;

  Future<void> call() => AppEvents.track(
    AppEvent.notificationMarkAllRead,
    () => _repository.markAllAsRead(),
  );
}
