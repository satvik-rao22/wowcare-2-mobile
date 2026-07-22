import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../domain/features/geofencing/entities/location_permission_level.dart';

abstract class GeofencingLocalDataSource {
  /// Reads the current permission level without prompting the OS dialog.
  Future<LocationPermissionLevel> getPermissionLevel();

  /// Requests foreground ("While Using the App") location permission only —
  /// never escalates to background/"Always" automatically.
  Future<LocationPermissionLevel> requestLocationPermission();
  Future<bool> isLocationServiceEnabled();
  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
}

class GeofencingLocalDataSourceImpl implements GeofencingLocalDataSource {
  /// Maps Geolocator's iOS [LocationPermission] to [LocationPermissionLevel].
  /// iOS does not distinguish "Allow Once" from "Allow While Using the App"
  /// at the API level — both report as `.whileInUse` and both map to
  /// [LocationPermissionLevel.whileInUse] here.
  LocationPermissionLevel _mapIOSPermission(LocationPermission perm) {
    switch (perm) {
      case LocationPermission.always:
        return LocationPermissionLevel.always;
      case LocationPermission.whileInUse:
        return LocationPermissionLevel.whileInUse;
      case LocationPermission.deniedForever:
        return LocationPermissionLevel.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionLevel.denied;
    }
  }

  /// Maps Android's foreground + background [PermissionStatus] pair to
  /// [LocationPermissionLevel]. Reads `locationAlways`'s current status only
  /// (never requests it) so this never triggers a background permission prompt.
  Future<LocationPermissionLevel> _mapAndroidPermission(
    PermissionStatus foreground,
  ) async {
    if (foreground.isPermanentlyDenied) {
      return LocationPermissionLevel.permanentlyDenied;
    }
    if (!foreground.isGranted) {
      return LocationPermissionLevel.denied;
    }
    final background = await Permission.locationAlways.status;
    return background.isGranted
        ? LocationPermissionLevel.always
        : LocationPermissionLevel.whileInUse;
  }

  @override
  Future<LocationPermissionLevel> getPermissionLevel() async {
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
      final level = _mapIOSPermission(perm);
      debugPrint('[GeofenceDS] iOS getPermissionLevel: $perm → $level');
      return level;
    }
    // Android: permission_handler is correctly configured via AndroidManifest.xml.
    final status = await Permission.location.status;
    final level = await _mapAndroidPermission(status);
    debugPrint('[GeofenceDS] Android getPermissionLevel: $status → $level');
    return level;
  }

  @override
  Future<LocationPermissionLevel> requestLocationPermission() async {
    if (Platform.isIOS) {
      // On iOS, use Geolocator.requestPermission() for the same reason as
      // getPermissionLevel() above. This is now the sole request path —
      // GeofencePlugin.swift no longer requests permission at native init or
      // auto-escalates When-In-Use to Always, so this call is authoritative
      // and only ever asks for what the OS prompt naturally offers next.
      final perm = await Geolocator.requestPermission();
      final level = _mapIOSPermission(perm);
      debugPrint('[GeofenceDS] iOS requestLocationPermission: $perm → $level');
      return level;
    }
    // Android: request only foreground ("While Using the App") location.
    // Background ("Always") is never requested automatically here — it must
    // be a deliberate, separate request triggered by explicit user action.
    final status = await Permission.location.request();
    final level = await _mapAndroidPermission(status);
    debugPrint('[GeofenceDS] Android requestLocationPermission: $status → $level');
    return level;
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
  Stream<Position> getPositionStream() async* {
    // Background delivery on iOS is only valid — and only requested — when the
    // user has actually granted "Always". For "Allow Once"/"While Using the
    // App" the stream must behave as a plain foreground-only stream, or it
    // bypasses the native gating in GeofencePlugin.swift entirely by asking
    // Geolocator's own internal CLLocationManager to keep delivering updates
    // in the background regardless of the granted permission level.
    final permissionLevel =
        Platform.isIOS ? await getPermissionLevel() : null;
    final isAlways = permissionLevel == LocationPermissionLevel.always;

    final LocationSettings settings = Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
            allowBackgroundLocationUpdates: isAlways,
            showBackgroundLocationIndicator: isAlways,
            activityType: ActivityType.other,
            pauseLocationUpdatesAutomatically: !isAlways,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          );

    yield* Geolocator.getPositionStream(locationSettings: settings).where(
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
