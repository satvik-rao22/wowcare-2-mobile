import 'package:workmanager/workmanager.dart';
import 'package:wowcare/core/background/geofence_background_task.dart';

/// WorkManager entry point — must be a top-level (or static) function.
/// Registered once here; whether a task is actually scheduled is decided
/// entirely by GeofenceCubit based on permission level + admin GPS setting
/// (see _syncBackgroundHealthCheck), not by this initialization call.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == geofenceHealthCheckTaskName) {
      await geofenceBackgroundCallback();
    }
    return true;
  });
}
