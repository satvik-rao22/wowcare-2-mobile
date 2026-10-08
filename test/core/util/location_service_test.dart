import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:wowcare/core/utils/location_service.dart';

import 'fake_permission_platforms.dart';

const _school = GeofenceArea(
  latitude: 12.9716,
  longitude: 77.5946,
  radiusMeters: 200,
);

/// 0.001° of latitude ≈ 111 m.
const _metresPerMilliDegree = 111.0;

Position _position({
  double metresNorth = 0,
  double accuracy = 10,
  bool mocked = false,
  Duration age = Duration.zero,
}) => Position(
  latitude: _school.latitude + metresNorth / _metresPerMilliDegree * 0.001,
  longitude: _school.longitude,
  timestamp: DateTime.now().toUtc().subtract(age),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

LocationPoint _point({double metresNorth = 0, double accuracy = 10}) =>
    LocationPoint(
      latitude: _school.latitude + metresNorth / _metresPerMilliDegree * 0.001,
      longitude: _school.longitude,
      accuracyMeters: accuracy,
      timestamp: DateTime.now(),
    );

class _FakeGeolocator extends FakeGeolocator {
  Position? lastKnown;
  final live = StreamController<Position>();

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      live.stream;
}

void main() {
  late _FakeGeolocator geolocator;

  setUp(() {
    geolocator = _FakeGeolocator();
    GeolocatorPlatform.instance = geolocator;
  });

  group('geofenceStatus', () {
    test('inside the radius → within', () {
      expect(
        LocationService.geofenceStatus(_point(metresNorth: 150), _school),
        GeofenceStatus.within,
      );
    });

    test('far beyond radius + buffer → outside', () {
      expect(
        LocationService.geofenceStatus(_point(metresNorth: 1000), _school),
        GeofenceStatus.outside,
      );
    });

    test('just past the edge → unknown (could be GPS noise)', () {
      // 230 m: past the 200 m radius but within the 50 m exit buffer.
      expect(
        LocationService.geofenceStatus(_point(metresNorth: 230), _school),
        GeofenceStatus.unknown,
      );
    });

    test('a coarse fix that might be inside → unknown, not outside', () {
      // 400 m away, but ±300 m means the user could be at the school.
      expect(
        LocationService.geofenceStatus(
          _point(metresNorth: 400, accuracy: 300),
          _school,
        ),
        GeofenceStatus.unknown,
      );
    });
  });

  group('getCurrentLocation', () {
    test('returns the fresh fix', () async {
      geolocator.currentPosition = _position(metresNorth: 10, mocked: true);

      final location = await LocationService.getCurrentLocation();

      expect(location, isNotNull);
      expect(location!.isMocked, isTrue);
    });

    test('no fix → null; the last known fix is not used by default', () async {
      geolocator.lastKnown = _position();

      expect(await LocationService.getCurrentLocation(), isNull);
    });

    test('no fix + fallbackToLastKnown → last known fix', () async {
      geolocator.lastKnown = _position(metresNorth: 42);

      final location = await LocationService.getCurrentLocation(
        fallbackToLastKnown: true,
      );

      expect(location, isNotNull);
      expect(
        LocationService.distanceInMeters(location!, _school),
        closeTo(42, 1),
      );
    });
  });

  test('watchGeofence ignores fake, coarse, stale and unsure fixes', () async {
    final statuses = <GeofenceStatus>[];
    final sub = LocationService.watchGeofence(_school).listen(statuses.add);

    geolocator.live
      ..add(_position(mocked: true)) // fake GPS
      ..add(_position(accuracy: 900)) // too coarse
      ..add(_position(age: const Duration(minutes: 5))) // stale cache
      ..add(_position(metresNorth: 230)) // unsure, near the edge
      ..add(_position(metresNorth: 1000)) // clearly outside
      ..add(_position(metresNorth: 50)); // inside
    await Future<void>.delayed(Duration.zero);

    expect(statuses, [GeofenceStatus.outside, GeofenceStatus.within]);
    await sub.cancel();
  });
}
