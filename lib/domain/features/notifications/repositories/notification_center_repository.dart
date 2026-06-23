import '../entities/app_notification.dart';

/// One page of notification-center items plus whether more pages exist.
typedef NotificationPage = ({List<AppNotification> items, bool hasMore});

/// Abstraction over the notification-center backend (the bell-icon inbox).
///
/// Kept separate from [PushNotificationRepository] (FCM transport): this seam
/// owns the persisted, browsable list and its read-state mutations. The
/// concrete implementation currently talks to a mock data source; swapping in a
/// real REST data source is a single-file change behind this interface.
abstract class NotificationCenterRepository {
  /// Fetches one page of notification-center items, newest first.
  /// [page] is zero-based.
  Future<NotificationPage> getNotifications({int page, int size});

  /// Marks a single notification as read on the backend.
  Future<void> markAsRead(String id);

  /// Marks every notification as read on the backend.
  Future<void> markAllAsRead();
}
