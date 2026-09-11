import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Name registered with WorkManager for the periodic health-check task.
const String geofenceHealthCheckTaskUniqueName = 'geofence-health-check';

/// Task name passed to `Workmanager().registerPeriodicTask` — matched against
/// in [callbackDispatcher] to dispatch to [geofenceBackgroundCallback].
const String geofenceHealthCheckTaskName = 'geofenceBackgroundTask';

/// WorkManager health-check/recovery task — NOT the primary tracking
/// mechanism. Real-time geofencing, GPS polling, and attendance decisions are
/// owned entirely by native region monitoring (CLLocationManager region
/// monitoring on iOS, GeofencingClient on Android) and the foreground
/// GeofenceCubit. This task only re-invokes the same native registration
/// call the app makes on init, as a best-effort recovery in case native
/// monitoring was silently dropped by the OS (e.g. after certain reboots or
/// OS updates) while the app was terminated.
///
/// This runs independently of the main app in a background isolate.
Future<void> geofenceBackgroundCallback() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('geofence_school_lat');
    final longitude = prefs.getDouble('geofence_school_lon');
    final radiusMeters = prefs.getDouble('geofence_school_radius_m');
    final schoolCode = prefs.getString('geofence_school_code');
    final gpsSignInEnabled =
        prefs.getBool('geofence_gps_sign_in_enabled') ?? true;

    // Nothing to recover if there's no persisted config, or the school has
    // GPS sign-in turned off — do not re-register in that case.
    if (latitude == null ||
        longitude == null ||
        schoolCode == null ||
        !gpsSignInEnabled) {
      return;
    }

    // Recovery only: re-invoke the SAME native registration path the app
    // uses on init. Does NOT compute distance, does NOT decide geofence
    // status, does NOT fire notifications — the native side
    // (GeofencePlugin.swift / GeofencePlugin.kt) owns all of that, exactly as
    // it does during a normal app-driven registration via GeofenceCubit.
    const channel = MethodChannel('com.wowcare.geofencing/native');
    await channel.invokeMethod('updateSchoolLocation', {
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters ?? 250.0,
      'schoolCode': schoolCode,
      'gpsSignInEnabled': gpsSignInEnabled,
    });
  } catch (_) {
    // Best-effort recovery — never crash the background isolate.
  }
}
