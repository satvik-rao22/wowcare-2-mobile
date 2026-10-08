import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wowcare/core/firebase/firebase_initializer.dart';
import 'package:wowcare/core/notifications/notification_channel_service.dart';
import 'package:wowcare/core/utils/html_entities.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Handle FCM messages in background / terminated state.
///
/// Runs in a separate Dart isolate — no DI, no service locator available.
/// For notification messages (FCM payload has a `notification` field) Android
/// already shows the system tray notification automatically; we only need to
/// act on data-only messages which Android silently drops without this handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await ensureFirebaseInitialized();

    AppLogger.d('[FCM] ════════ Background notification received ════════');
    AppLogger.d('[FCM] messageId : ${message.messageId}');
    AppLogger.d('[FCM] from      : ${message.from}');
    AppLogger.d('[FCM] title     : ${message.notification?.title}');
    AppLogger.d('[FCM] body      : ${message.notification?.body}');
    AppLogger.d('[FCM] android   : ${message.notification?.android}');
    AppLogger.d('[FCM] data      : ${message.data}');
    AppLogger.d('[FCM] ═══════════════════════════════════════════════════');

    // Data-only messages: Android doesn't show anything automatically.
    // Show a local notification so the user always sees the alert.
    if (message.notification == null) {
      final title = HtmlEntities.decode(
        message.data['title']?.toString() ?? 'WowCare',
      );
      final body = HtmlEntities.decode(
        message.data['body']?.toString() ?? 'You have a new notification',
      );
      AppLogger.d('[FCM] Background data-only → showing local notif "$title"');

      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_launcher_foreground'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await createDefaultNotificationChannel(plugin);
      await plugin.show(
        id: message.messageId.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            pushChannelId,
            pushChannelName,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
      );
    }
  } catch (e, stackTrace) {
    try {
      await ensureFirebaseInitialized();
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        fatal: true,
      );
    } catch (_) {}
  }
}
