import 'package:flutter/services.dart';

/// Native bridge to read the FCM `data` payload of the notification that
/// cold-launched the app (killed state) — a reliable fallback for
/// FirebaseMessaging.getInitialMessage() returning null with our manual plugin
/// registration. See MainActivity.consumeLaunchNotificationData().
const MethodChannel _notificationChannel = MethodChannel(
  'wowcare/notifications',
);

Future<Map<String, String>?> readNativeLaunchNotification() async {
  try {
    final raw = await _notificationChannel.invokeMapMethod<String, dynamic>(
      'getInitialNotificationData',
    );
    if (raw == null) return null;
    return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  } catch (_) {
    return null;
  }
}
