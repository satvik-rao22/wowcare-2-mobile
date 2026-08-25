import 'package:wowcare/core/util/active_school_switcher.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/notification_payload.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GeofenceNotificationService {
  static const String _channelId = 'geofence_channel';
  static const String _channelName = 'School Sign-In Zone Alerts';

  // Dedicated high-importance channel for ALL push notifications (any module),
  // so every push plays the system notification tune + vibrates. A NEW channel
  // id (not the legacy 'push_background_channel') guarantees a fresh, audible
  // channel is created even on devices where an older silent channel exists —
  // Android locks a channel's sound/importance at creation time, so re-using an
  // old id would keep it silent. Keep this id in sync with main.dart and the
  // AndroidManifest's `default_notification_channel_id`.
  static const String pushChannelId = 'wowcare_alerts_v2';
  static const String pushChannelName = 'WowCare Notifications';

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
      const androidInit = AndroidInitializationSettings(
        'ic_launcher_foreground',
      );
      // Request iOS alert/sound permission at init so the system prompt appears
      // as soon as GPS monitoring starts, not silently after the first event.
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channels for Android 8.0+.
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // Geofence sign-in zone alerts.
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
      // Push notifications (all modules) — system sound + vibration.
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          pushChannelId,
          pushChannelName,
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
    // Route through the dedicated push channel so every module's notification
    // plays the system tune.
    channelId: pushChannelId,
    channelName: pushChannelName,
  );

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required bool isCritical,
    String? payload,
    String channelId = _channelId,
    String channelName = _channelName,
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
            channelId,
            channelName,
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
    final raw = response.payload?.trim();
    if (raw == null || raw.isEmpty) return;
    final decoded = decodeNotificationPayload(raw);
    final ctx = CoreUtils.rootNavigatorKey.currentContext;
    // If the notification targets a different school the user belongs to, switch
    // the active org/school BEFORE routing (mirrors the background-tap path).
    if (ctx != null &&
        (decoded.organizationCode ?? '').isNotEmpty &&
        (decoded.schoolCode ?? '').isNotEmpty) {
      () async {
        try {
          await switchActiveSchoolIfNeeded(
            context: ctx,
            organizationCode: decoded.organizationCode,
            schoolCode: decoded.schoolCode,
          );
        } catch (e) {
          AppLogger.d('[FCM] Foreground tap school-switch failed: $e');
        }
        try {
          appRouter.go(decoded.location);
        } catch (e) {
          AppLogger.d('[FCM] Foreground tap route failed for "$raw": $e');
        }
      }();
      return;
    }
    try {
      appRouter.go(decoded.location);
    } catch (e) {
      AppLogger.d('[FCM] Foreground tap route failed for "$raw": $e');
    }
  }
}
