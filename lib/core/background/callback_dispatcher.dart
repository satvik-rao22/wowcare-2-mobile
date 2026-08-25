import 'package:workmanager/workmanager.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wowcare/core/background/geofence_background_task.dart';
import 'package:wowcare/core/firebase/firebase_initializer.dart';

/// WorkManager entry point — must be a top-level (or static) function.
/// Registered once here; whether a task is actually scheduled is decided
/// entirely by GeofenceCubit based on permission level + admin GPS setting
/// (see _syncBackgroundHealthCheck), not by this initialization call.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == geofenceHealthCheckTaskName) {
        await geofenceBackgroundCallback();
      }
      return true;
    } catch (e, stackTrace) {
      try {
        await ensureFirebaseInitialized();
        await FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          fatal: true,
        );
      } catch (_) {}
      return false;
    }
  });
}
