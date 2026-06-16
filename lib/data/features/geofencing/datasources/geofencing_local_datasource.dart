import 'dart:io';
import 'package:flutter/foundation.dart';
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
    if (Platform.isIOS) {
      // Use Geolocator directly on iOS.
      //
      // permission_handler's LocationPermissionStrategy is compiled behind
      // a #if PERMISSION_LOCATION preprocessor guard. If PERMISSION_LOCATION=1
      // is missing from the Podfile's GCC_PREPROCESSOR_DEFINITIONS, every call
      // to Permission.location.status silently returns PermissionStatus.denied,
      // making the permission gate always fail on iOS regardless of what the
      // user has granted. Geolocator uses CLLocationManager internally and is
      // immune to this Podfile flag — it is therefore the authoritative source
      // of truth for location permission on iOS.
      final perm = await Geolocator.checkPermission();
      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      debugPrint('[GeofenceDS] iOS hasLocationPermission: $perm → $granted');
      return granted;
    }
    // Android: permission_handler is correctly configured via AndroidManifest.xml.
    final status = await Permission.location.status;
    debugPrint('[GeofenceDS] Android hasLocationPermission: $status');
    return status.isGranted;
  }

  @override
  Future<bool> requestLocationPermission() async {
    if (Platform.isIOS) {
      // On iOS, use Geolocator.requestPermission() for the same reason as
      // hasLocationPermission() above. GeofencePlugin.swift also calls
      // requestWhenInUseAuthorization() at startup and escalates to
      // requestAlwaysAuthorization() when "When In Use" is granted — this
      // Dart call handles the case where the native plugin fires before the
      // Dart side has had a chance to request.
      final perm = await Geolocator.requestPermission();
      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      debugPrint('[GeofenceDS] iOS requestLocationPermission: $perm → $granted');
      return granted;
    }
    // Android: request "When In Use" first, then escalate to "Always" so
    // GeofencingClient can fire events when the app is backgrounded/killed.
    final status = await Permission.location.request();
    if (status.isGranted) {
      await Permission.locationAlways.request();
    }
    debugPrint('[GeofenceDS] Android requestLocationPermission: $status → ${status.isGranted}');
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
        if (position.isMocked) {
          debugPrint('[GeofenceStream] ❌ Rejected mocked position');
          return false;
        }

        // Reject implausible accuracy: 0 = faked; >500 m = too coarse for geofencing.
        // iOS WiFi/cell fixes commonly report 200–400 m accuracy, so 500 m ceiling
        // keeps those positions in. The cubit's hysteresis logic handles coarse fixes.
        if (position.accuracy <= 0 || position.accuracy > 500) {
          debugPrint('[GeofenceStream] ❌ Rejected position — accuracy=±${position.accuracy.toStringAsFixed(1)}m (out of 0–500 m range)');
          return false;
        }

        // Reject stale cached positions older than 60 seconds.
        final age = DateTime.now().toUtc().difference(position.timestamp);
        if (age.inSeconds > 60) {
          debugPrint('[GeofenceStream] ❌ Rejected stale position — age=${age.inSeconds}s');
          return false;
        }

        debugPrint('[GeofenceStream] ✅ Accepted — lat=${position.latitude} lon=${position.longitude} accuracy=±${position.accuracy.toStringAsFixed(1)}m age=${age.inSeconds}s');
        return true;
      },
    );
  }
}
