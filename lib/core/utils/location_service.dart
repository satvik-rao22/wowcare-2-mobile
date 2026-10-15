import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// The one place the app reads the device's location and checks whether
/// it is inside a geofence (e.g. the school's sign-in area).
///
/// No setup — import this file and call it:
///
/// ```dart
/// // GPS for a request payload (null when there is no fix):
/// final location = await LocationService.getCurrentLocation(
///   fallbackToLastKnown: true,
/// );
///
/// // Is this fix inside the school's area?
/// final status = LocationService.geofenceStatus(location, config.area);
///
/// // Live inside/outside changes while the app is open:
/// LocationService.watchGeofence(config.area).listen(...);
/// ```
///
/// Permissions and the GPS on/off switch are not handled here — use
/// PermissionManager first. Location is foreground-only: nothing here keeps
/// running in the background.
///
/// The Geolocator plugin stays inside this file, so upgrading or swapping it
/// changes nothing at the call sites.
abstract final class LocationService {
  /// Extra distance beyond the radius before a fix counts as clearly
  /// outside. Stops the status flickering for someone standing at the edge.
  static const double exitBufferMeters = 50;

  /// Fixes worse than this (or reporting 0, which only fake GPS does) are
  /// too coarse to decide inside/outside and are dropped from the live stream.
  static const double _maxUsableAccuracyMeters = 500;

  /// Live-stream fixes older than this are cached ones, not live.
  static const Duration _maxLiveFixAge = Duration(seconds: 60);

  /// A fresh GPS fix, or null when none arrives within [timeLimit].
  ///
  /// [fallbackToLastKnown] returns the phone's last cached fix instead of
  /// null. That fix can be minutes old and from anywhere, so leave it off
  /// for anything that decides whether the user is at school.
  ///
  /// Never throws. Mocked fixes are returned with [LocationPoint.isMocked]
  /// set, so the caller decides what a fake-GPS fix means.
  static Future<LocationPoint?> getCurrentLocation({
    Duration timeLimit = const Duration(seconds: 15),
    bool fallbackToLastKnown = false,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return LocationPoint._fromPosition(position);
    } catch (e) {
      AppLogger.d('[Location] No GPS fix within ${timeLimit.inSeconds}s: $e');
    }
    if (!fallbackToLastKnown) return null;
    try {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : LocationPoint._fromPosition(last);
    } catch (e) {
      AppLogger.d('[Location] No last known position: $e');
      return null;
    }
  }

  /// Live fixes while the app is in the foreground. Fake-GPS, too-coarse
  /// and stale fixes are dropped, so every value is safe to act on.
  static Stream<LocationPoint> watchLocation() {
    // iOS: background delivery stays off — the app holds no background
    // location permission (App Store guideline 2.5.4, see Info.plist).
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
    return Geolocator.getPositionStream(
      locationSettings: settings,
    ).map(LocationPoint._fromPosition).where(_isUsableLiveFix);
  }

  /// Emits [GeofenceStatus.within] / [GeofenceStatus.outside] as the user
  /// moves. Fixes too unsure to call (see [geofenceStatus]) are skipped,
  /// so the last confident status holds.
  static Stream<GeofenceStatus> watchGeofence(GeofenceArea area) =>
      watchLocation()
          .map((point) => geofenceStatus(point, area))
          .where((status) => status != GeofenceStatus.unknown);

  /// Inside, outside, or too unsure to say — the one geofence rule in the app.
  ///
  /// - **within**: the fix is inside the radius.
  /// - **outside**: even allowing for the fix's accuracy, it is more than
  ///   [exitBufferMeters] beyond the radius.
  /// - **unknown**: in between — a noisy fix near the edge.
  ///
  /// For a yes/no answer ("can they sign in?"), use `== GeofenceStatus.within`.
  static GeofenceStatus geofenceStatus(LocationPoint point, GeofenceArea area) {
    final distance = distanceInMeters(point, area);
    if (distance <= area.radiusMeters) return GeofenceStatus.within;
    final closestPossible = distance - point.accuracyMeters;
    if (closestPossible > area.radiusMeters + exitBufferMeters) {
      return GeofenceStatus.outside;
    }
    return GeofenceStatus.unknown;
  }

  /// Straight-line distance from [point] to the centre of [area].
  static double distanceInMeters(LocationPoint point, GeofenceArea area) =>
      Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        area.latitude,
        area.longitude,
      );

  static bool _isUsableLiveFix(LocationPoint point) {
    if (point.isMocked) {
      AppLogger.d('[Location] Dropped fake-GPS fix');
      return false;
    }
    if (point.accuracyMeters <= 0 ||
        point.accuracyMeters > _maxUsableAccuracyMeters) {
      AppLogger.d('[Location] Dropped fix, accuracy ±${point.accuracyMeters}m');
      return false;
    }
    if (point.age > _maxLiveFixAge) {
      AppLogger.d('[Location] Dropped stale fix, age ${point.age.inSeconds}s');
      return false;
    }
    return true;
  }
}

/// Where the device is, as reported by one GPS fix.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    this.isMocked = false,
  });

  LocationPoint._fromPosition(Position p)
    : latitude = p.latitude,
      longitude = p.longitude,
      accuracyMeters = p.accuracy < 0 ? 0 : p.accuracy,
      timestamp = p.timestamp,
      isMocked = p.isMocked;

  final double latitude;
  final double longitude;

  /// The true position is within this many metres of the fix.
  final double accuracyMeters;
  final DateTime timestamp;

  /// Came from a fake-GPS (mock location) app. Android only — iOS never sets it.
  final bool isMocked;

  Duration get age => DateTime.now().toUtc().difference(timestamp.toUtc());

  @override
  String toString() =>
      'LocationPoint($latitude, $longitude, ±${accuracyMeters.toStringAsFixed(1)}m, '
      'age ${age.inSeconds}s${isMocked ? ', MOCKED' : ''})';
}

/// A circle on the map, e.g. the school's sign-in area.
class GeofenceArea {
  const GeofenceArea({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
}

enum GeofenceStatus { unknown, within, outside }
