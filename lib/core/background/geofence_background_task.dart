import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback for WorkManager to check geofence in background.
/// This runs independently of the main app in an isolate.
Future<void> geofenceBackgroundCallback() async {
  try {
    // Get last stored school coordinates and check from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('geofence_school_lat');
    final longitude = prefs.getDouble('geofence_school_lon');
    final lastNotifiedInside =
        prefs.getBool('geofence_last_notified_inside') ?? false;

    // If no school coordinates stored, skip this task
    if (latitude == null || longitude == null) {
      return;
    }

    // Get last known position (doesn't require active location service)
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition == null) {
      return;
    }

    // Calculate distance to school
    final distanceMeters = Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      latitude,
      longitude,
    );

    final isWithinRange = distanceMeters <= 228.6; // 250 yards
    final shouldNotify = isWithinRange != lastNotifiedInside;

    if (shouldNotify) {
      // Store notification state
      await prefs.setBool('geofence_last_notified_inside', isWithinRange);

      // Show local notification
      final plugin = FlutterLocalNotificationsPlugin();
      if (isWithinRange) {
        await plugin.show(
          id: 1001,
          title: 'You are now within school sign-in range',
          body: 'Tap to sign your child in or out.',
          notificationDetails: NotificationDetails(
            android: const AndroidNotificationDetails(
              'geofence_channel',
              'School Sign-In Zone Alerts',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: false,
              presentSound: true,
            ),
          ),
        );
      } else {
        await plugin.show(
          id: 1002,
          title: 'You left the school sign-in zone',
          body: 'GPS sign-in is unavailable until you return.',
          notificationDetails: NotificationDetails(
            android: const AndroidNotificationDetails(
              'geofence_channel',
              'School Sign-In Zone Alerts',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: false,
              presentSound: true,
            ),
          ),
        );
      }
    }
  } catch (e) {
    // Silently fail - background task should not crash the app
  }
}
