import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Location permission and the GPS on/off check live in PermissionManager
/// (core/utils); this only reads positions.
abstract class GeofencingLocalDataSource {
  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
}

class GeofencingLocalDataSourceImpl implements GeofencingLocalDataSource {
  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );

  @override
  Stream<Position> getPositionStream() async* {
    // iOS: background delivery is off unconditionally. The app holds no
    // background location permission (guideline 2.5.4 — see Info.plist), so
    // asking Geolocator's internal CLLocationManager for background updates
    // would either throw or be silently dropped. Position updates arrive only
    // while the app is in the foreground.
    final LocationSettings settings = Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
            allowBackgroundLocationUpdates: false,
            showBackgroundLocationIndicator: false,
            activityType: ActivityType.other,
            pauseLocationUpdatesAutomatically: true,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          );

    yield* Geolocator.getPositionStream(locationSettings: settings).where((
      position,
    ) {
      // Security: reject mocked / fake GPS (Android only — iOS never sets isMocked).
      if (position.isMocked) {
        debugPrint('[GeofenceStream] ❌ Rejected mocked position');
        return false;
      }

      // Reject implausible accuracy: 0 = faked; >500 m = too coarse for geofencing.
      // iOS WiFi/cell fixes commonly report 200–400 m accuracy, so 500 m ceiling
      // keeps those positions in. The cubit's hysteresis logic handles coarse fixes.
      if (position.accuracy <= 0 || position.accuracy > 500) {
        debugPrint(
          '[GeofenceStream] ❌ Rejected position — accuracy=±${position.accuracy.toStringAsFixed(1)}m (out of 0–500 m range)',
        );
        return false;
      }

      // Reject stale cached positions older than 60 seconds.
      final age = DateTime.now().toUtc().difference(position.timestamp);
      if (age.inSeconds > 60) {
        debugPrint(
          '[GeofenceStream] ❌ Rejected stale position — age=${age.inSeconds}s',
        );
        return false;
      }

      debugPrint(
        '[GeofenceStream] ✅ Accepted — lat=${position.latitude} lon=${position.longitude} accuracy=±${position.accuracy.toStringAsFixed(1)}m age=${age.inSeconds}s',
      );
      return true;
    });
  }
}
