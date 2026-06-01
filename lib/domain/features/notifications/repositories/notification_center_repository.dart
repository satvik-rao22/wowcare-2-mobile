import '../entities/app_notification.dart';

/// Abstraction over the notification-center backend (the bell-icon inbox).
///
/// Kept separate from [PushNotificationRepository] (FCM transport): this seam
/// owns the persisted, browsable list and its read-state mutations. The
/// concrete implementation currently talks to a mock data source; swapping in a
/// real REST data source is a single-file change behind this interface.
abstract class NotificationCenterRepository {
  /// Fetches all notification-center items, newest first.
  Future<List<AppNotification>> getNotifications();

  /// Marks a single notification as read. Returns the updated list so callers
  /// can reflect server-side truth without a second round-trip.
  Future<List<AppNotification>> markAsRead(String id);

  /// Marks every notification as read. Returns the updated list.
  Future<List<AppNotification>> markAllAsRead();
}
