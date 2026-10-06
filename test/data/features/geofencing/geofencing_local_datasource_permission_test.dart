import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:wowcare/data/features/geofencing/datasources/geofencing_local_datasource.dart';
import 'package:wowcare/domain/features/geofencing/entities/location_permission_level.dart';

import '../../../core/util/fake_permission_platforms.dart';

/// Locks the location-level mapping the geofence cubit depends on: `always`
/// keeps monitoring alive in the background and registers the WorkManager
/// health check, so it must appear exactly where it did before the move to
/// PermissionManager — and never on iOS.
void main() {
  late FakePermissionHandler handler;
  late FakeGeolocator geolocator;
  final dataSource = GeofencingLocalDataSourceImpl();

  setUp(() {
    handler = FakePermissionHandler();
    geolocator = FakeGeolocator();
    PermissionHandlerPlatform.instance = handler;
    GeolocatorPlatform.instance = geolocator;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('foreground only → whileInUse', () async {
      handler.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;
      handler.statuses[Permission.locationAlways] = PermissionStatus.denied;

      expect(
        await dataSource.getPermissionLevel(),
        LocationPermissionLevel.whileInUse,
      );
    });

    test('background granted → always', () async {
      handler.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;
      handler.statuses[Permission.locationAlways] = PermissionStatus.granted;

      expect(
        await dataSource.getPermissionLevel(),
        LocationPermissionLevel.always,
      );
    });

    test('denied / permanently denied map through', () async {
      handler.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;
      expect(
        await dataSource.getPermissionLevel(),
        LocationPermissionLevel.denied,
      );

      handler.statuses[Permission.locationWhenInUse] =
          PermissionStatus.permanentlyDenied;
      expect(
        await dataSource.getPermissionLevel(),
        LocationPermissionLevel.permanentlyDenied,
      );
    });

    test('request asks for foreground only', () async {
      handler.requestResults[Permission.locationWhenInUse] =
          PermissionStatus.granted;

      expect(
        await dataSource.requestLocationPermission(),
        LocationPermissionLevel.whileInUse,
      );
      expect(handler.requestCount, 1);
      expect(handler.statuses[Permission.locationAlways], isNull);
    });
  });

  group('iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('reads Geolocator; even an old "Always" grant → whileInUse', () async {
      // permission_handler can't see iOS location (PERMISSION_LOCATION unset).
      handler.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;
      handler.statuses[Permission.locationAlways] = PermissionStatus.granted;
      geolocator.status = LocationPermission.always;

      expect(
        await dataSource.getPermissionLevel(),
        LocationPermissionLevel.whileInUse,
      );
    });

    test('deniedForever → permanentlyDenied', () async {
      geolocator.status = LocationPermission.deniedForever;

      expect(
        await dataSource.getPermissionLevel(),
        LocationPermissionLevel.permanentlyDenied,
      );
    });

    test('request goes through Geolocator', () async {
      geolocator.requestResult = LocationPermission.whileInUse;

      expect(
        await dataSource.requestLocationPermission(),
        LocationPermissionLevel.whileInUse,
      );
      expect(geolocator.requestCount, 1);
      expect(handler.requestCount, 0);
    });
  });
}
