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
    final status = await Permission.location.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Android 10+ requires background location as a separate request step
      // so GeofencingClient can fire events when the app is backgrounded/killed.
      // iOS: the native GeofencePlugin handles requestAlwaysAuthorization() itself.
      // Best-effort — foreground GPS still works if the user denies "Allow all the time".
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
  Stream<Position> getPositionStream() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
      // Do NOT set timeLimit on a stream — it causes a TimeoutException after
      // the duration, killing the stream and disabling the sign-in button.
      // timeLimit is only valid for one-shot getCurrentPosition() calls.
    ),
  ).where((position) {
    // Security: reject mocked / fake GPS
    if (position.isMocked) return false;

    // Security: reject implausible accuracy (0 = faked; >150 m = too coarse)
    if (position.accuracy <= 0 || position.accuracy > 150) return false;

    // Security: reject stale cached positions older than 60 seconds
    final age = DateTime.now().toUtc().difference(position.timestamp);
    if (age.inSeconds > 60) return false;

    return true;
  });
}
