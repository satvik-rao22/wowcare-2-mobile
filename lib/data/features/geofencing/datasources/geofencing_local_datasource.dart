import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


abstract class GeofencingLocalDataSource {
  Future<bool> hasLocationPermission();
  Future<bool> requestLocationPermission();
  Future<bool> isLocationServiceEnabled();
  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
}

class GeofencingLocalDataSourceImpl implements GeofencingLocalDataSource {
  @override
  Future<bool> hasLocationPermission() async {
    // iOS region monitoring requires "Always" — "When In Use" is not sufficient
    // for background geofence events. Accept either; the native plugin escalates
    // to "Always" via requestAlwaysAuthorization() when needed.
    if (Platform.isIOS) {
      final alwaysStatus = await Permission.locationAlways.status;
      if (alwaysStatus.isGranted) return true;
      final whenInUseStatus = await Permission.location.status;
      return whenInUseStatus.isGranted;
    }
    final status = await Permission.location.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted && !Platform.isIOS) {
      // Android 10+ requires background location as a separate request step
      // so GeofencingClient can fire events when the app is backgrounded/killed.
      // iOS: GeofencePlugin.swift calls requestAlwaysAuthorization() itself inside
      // handleUpdateSchoolLocation. Calling it here too would consume the one-time
      // iOS permission dialog before the native plugin runs, silently dropping it.
      await Permission.locationAlways.request();
    }
    return status.isGranted;
  }

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );

  @override
  Stream<Position> getPositionStream() {
    // iOS requires AppleSettings with allowBackgroundLocationUpdates: true so
    // the stream keeps delivering positions after the app is backgrounded.
    // Without this the stream silently dies when the screen locks, leaving the
    // sign-in button stuck on whatever state it had in the foreground.
    // Android uses the generic LocationSettings path (no background flag needed
    // because the Android side uses OS-level GeofencingClient, not this stream).
    final LocationSettings settings = Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
            allowBackgroundLocationUpdates: true,
            showBackgroundLocationIndicator: true,
            activityType: ActivityType.other,
            pauseLocationUpdatesAutomatically: false,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          );

    return Geolocator.getPositionStream(locationSettings: settings).where(
      (position) {
        // Security: reject mocked / fake GPS (Android only — iOS never sets isMocked).
        if (position.isMocked) return false;

        // Reject implausible accuracy: 0 = faked; >500 m = too coarse for geofencing.
        // iOS WiFi/cell fixes commonly report 200–400 m accuracy, so 500 m ceiling
        // keeps those positions in. The cubit's hysteresis logic handles coarse fixes.
        if (position.accuracy <= 0 || position.accuracy > 500) return false;

        // Reject stale cached positions older than 60 seconds.
        final age = DateTime.now().toUtc().difference(position.timestamp);
        if (age.inSeconds > 60) return false;

        return true;
      },
    );
  }
}
