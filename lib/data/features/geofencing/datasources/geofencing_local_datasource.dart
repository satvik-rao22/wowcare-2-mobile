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
      timeLimit: Duration(seconds: 30),
    ),
  ).where((position) {
    // Security: Reject mocked/fake GPS locations (Android API 18+)
    if (position.isMocked) {
      return false;
    }

    // Security: Reject implausible accuracy values
    // 0 or negative = obviously faked
    // > 150m = too coarse for 250-yard boundary detection
    if (position.accuracy <= 0 || position.accuracy > 150) {
      return false;
    }

    // Security: Reject positions older than 30 seconds (stale data)
    final now = DateTime.now().toUtc();
    final positionAge = now.difference(position.timestamp);
    if (positionAge.inSeconds > 30) {
      return false;
    }

    return true;
  });
}
