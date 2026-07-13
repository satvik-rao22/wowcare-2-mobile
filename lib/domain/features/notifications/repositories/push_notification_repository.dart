import '../entities/push_notification.dart';

/// Abstraction over the push-notification platform (FCM). Keeps Firebase out of
/// the presentation and domain layers so they depend on this seam, not the SDK.
abstract class PushNotificationRepository {
  /// Asks the OS for notification permission. Safe to call when already decided.
  Future<void> requestPermission();

  /// Current device FCM token (null when unavailable, e.g. no Play Services).
  Future<String?> getToken();

  /// Emits a new token whenever FCM rotates it.
  Stream<String> get onTokenRefresh;

  /// Messages received while the app is in the FOREGROUND (OS shows nothing).
  Stream<PushNotification> get onMessage;

  /// A notification TAPPED while the app was in the BACKGROUND (not killed).
  Stream<PushNotification> get onNotificationTap;

  /// The notification that LAUNCHED the app from a KILLED state, if any.
  Future<PushNotification?> getInitialMessage();
}
