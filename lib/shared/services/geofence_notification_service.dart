import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GeofenceNotificationService {
  static const String _channelId = 'geofence_channel';
  static const String _channelName = 'School Sign-In Zone Alerts';
  static const int _enteredId = 1001;
  static const int _exitedId = 1002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel for Android 8.0+
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
    } catch (e) {
      print('GeofenceNotificationService init failed: $e');
      // Continue without notifications - geofencing still works
      _initialized = false;
    }
  }

  Future<void> showEnteredZoneNotification() => _show(
        id: _enteredId,
        title: 'You are now within school sign-in range',
        body: 'Tap to sign your child in or out.',
        isCritical: true,
      );

  Future<void> showExitedZoneNotification() => _show(
        id: _exitedId,
        title: 'You left the school sign-in zone',
        body: 'GPS sign-in is unavailable until you return.',
        isCritical: false,
      );

  Future<void> showCustomNotification({
    required String title,
    required String body,
  }) =>
      _show(
        id: 1003,
        title: title,
        body: body,
        isCritical: true,
      );

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required bool isCritical,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: isCritical ? Importance.high : Importance.defaultImportance,
            priority: isCritical ? Priority.high : Priority.defaultPriority,
            enableVibration: isCritical,
            playSound: isCritical,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      // Notification failed - likely permissions issue
      // Silently fail - geofencing still works without notifications
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to sign-in flow if needed
  }
}
