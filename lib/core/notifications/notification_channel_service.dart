import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Keep in sync with GeofenceNotificationService.pushChannelId / the
/// AndroidManifest's default_notification_channel_id so every push uses one
/// audible, high-importance channel.
const String pushChannelId = 'wowcare_alerts_v2';
const String pushChannelName = 'WowCare Notifications';

/// Creates (or re-creates, idempotently) the shared Android notification
/// channel used by both the foreground/main-isolate setup and the
/// background/terminated FCM handler.
Future<void> createDefaultNotificationChannel(
  FlutterLocalNotificationsPlugin plugin,
) async {
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          pushChannelId,
          pushChannelName,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
}
