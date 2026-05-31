import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GeofenceNotificationService {
  static const String _channelId = 'geofence_channel';
  static const String _channelName = 'School Sign-In Zone Alerts';
  static const int _enteredId = 1001;
  static const int _exitedId = 1002;

  // Push notifications must each get a UNIQUE id — a fixed id makes every new
  // push replace the previous one in the tray, so firing 5 in a row leaves only
  // 1 visible. Start above the reserved geofence ids and increment per push.
  static int _nextPushId = 2000;

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
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel for Android 8.0+
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
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
      AppLogger.d('GeofenceNotificationService init failed: $e');
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
    String? payload,
  }) => _show(
    // Unique id per push so multiple notifications stack instead of replacing.
    id: _nextPushId++,
    title: title,
    body: body,
    isCritical: true,
    payload: payload,
  );

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required bool isCritical,
    String? payload,
  }) async {
    // Ensure the plugin is initialized so the tap handler
    // (onDidReceiveNotificationResponse → _onNotificationTapped) is registered.
    // Push notifications can show before geofencing ever runs init(), and
    // without this a foreground-notification tap would do nothing. init() is
    // idempotent.
    if (!_initialized) await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: isCritical
                ? Importance.high
                : Importance.defaultImportance,
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
    // Foreground push notifications carry their deep-link location as the
    // payload (set by PushNotificationCubit). Route to it on tap so foreground
    // taps behave like background-tray taps instead of doing nothing.
    final payload = response.payload?.trim();
    if (payload != null && payload.isNotEmpty) {
      try {
        appRouter.go(payload);
      } catch (e) {
        AppLogger.d('[FCM] Foreground tap route failed for "$payload": $e');
      }
    }
  }
}
