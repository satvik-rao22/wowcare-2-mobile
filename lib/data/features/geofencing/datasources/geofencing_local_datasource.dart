import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wowcare/core/utils/permission_manager.dart';

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
  /// Maps [PermissionManager]'s foreground location status to
  /// [LocationPermissionLevel]. Background ("all the time") access is only
  /// *read*, never requested, so this never triggers a background prompt.
  ///
  /// [LocationPermissionLevel.always] is never returned on iOS. The background
  /// location permission was removed for App Review guideline 2.5.4 — Info.plist
  /// declares neither the "Always" usage descriptions nor the `location`
  /// UIBackgroundMode, so the app cannot act on a background grant even where
  /// one survives from an older install. Collapsing it to [whileInUse] keeps
  /// the rest of the app (lifecycle gating, the WorkManager health check) on
  /// the foreground-only path it can actually honour on iOS.
  ///
  /// iOS does not distinguish "Allow Once" from "Allow While Using the App" at
  /// the API level, so both map to [LocationPermissionLevel.whileInUse].
  ///
  /// (On iOS, PermissionManager reads location through Geolocator, because
  /// the Podfile leaves permission_handler's PERMISSION_LOCATION unset.)
  Future<LocationPermissionLevel> _toLevel(AppPermissionStatus status) async {
    switch (status) {
      case AppPermissionStatus.granted:
        return await PermissionManager.isBackgroundLocationGranted()
            ? LocationPermissionLevel.always
            : LocationPermissionLevel.whileInUse;
      case AppPermissionStatus.denied:
        return LocationPermissionLevel.denied;
      case AppPermissionStatus.permanentlyDenied:
      case AppPermissionStatus.restricted:
        return LocationPermissionLevel.permanentlyDenied;
    }
  }

  @override
  Future<LocationPermissionLevel> getPermissionLevel() async {
    final status = await PermissionManager.status(AppPermission.location);
    final level = await _toLevel(status);
    debugPrint('[GeofenceDS] getPermissionLevel: $status → $level');
    return level;
  }

  /// Requests foreground ("While Using the App") location only. Background
  /// ("Always") is never requested here — GeofencePlugin.swift no longer
  /// requests at native init or auto-escalates either, so this call is the
  /// sole, authoritative request path.
  @override
  Future<LocationPermissionLevel> requestLocationPermission() async {
    final status = await PermissionManager.request(AppPermission.location);
    final level = await _toLevel(status);
    debugPrint('[GeofenceDS] requestLocationPermission: $status → $level');
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
