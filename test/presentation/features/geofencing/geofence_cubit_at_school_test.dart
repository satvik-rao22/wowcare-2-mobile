import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/domain/features/geofencing/entities/geofence_config.dart';
import 'package:wowcare/domain/features/geofencing/repositories/geofencing_repository.dart';
import 'package:wowcare/domain/features/geofencing/usecases/get_school_location_usecase.dart';
import 'package:wowcare/domain/features/geofencing/usecases/watch_geofence_usecase.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/services/geofence_notification_service.dart';

import '../../../core/util/fake_permission_platforms.dart';

const _schoolLat = 12.9716;
const _schoolLon = 77.5946;

class _FakeRepository implements GeofencingRepository {
  GeofenceConfig config = const GeofenceConfig(
    schoolCode: 'SCH1',
    latitude: _schoolLat,
    longitude: _schoolLon,
    radiusMeters: 200,
  );

  @override
  Future<GeofenceConfig> getSchoolLocation({
    required String schoolCode,
  }) async => config;

  @override
  Stream<Position> getPositionStream() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeNotifications implements GeofenceNotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Position _at(double lat, double lon, {bool mocked = false}) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: DateTime.now(),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePermissionHandler handler;
  late FakeGeolocator geolocator;
  late _FakeRepository repository;
  late GeofenceCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    handler = FakePermissionHandler();
    geolocator = FakeGeolocator();
    PermissionHandlerPlatform.instance = handler;
    GeolocatorPlatform.instance = geolocator;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    repository = _FakeRepository();
    cubit = GeofenceCubit(
      getSchoolLocationUseCase: GetSchoolLocationUseCase(repository),
      watchGeofenceUseCase: WatchGeofenceUseCase(repository),
      notificationService: _FakeNotifications(),
    );
  });

  tearDown(() async {
    await cubit.close();
    debugDefaultTargetPlatformOverride = null;
  });

  /// Location allowed, school loaded through the normal init.
  Future<void> startAtSchoolScreen() async {
    geolocator.status = LocationPermission.whileInUse;
    geolocator.currentPosition = _at(_schoolLat, _schoolLon);
    await cubit.initForSchool(schoolCode: 'SCH1');
  }

  test('at the school → atSchool, state withinRange', () async {
    await startAtSchoolScreen();

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.atSchool,
    );
    expect(cubit.state.status, GeofenceCubitStatus.withinRange);
  });

  test('~1 km away → notAtSchool, fixes a stale withinRange state', () async {
    await startAtSchoolScreen();
    expect(cubit.state.status, GeofenceCubitStatus.withinRange);

    geolocator.currentPosition = _at(_schoolLat + 0.01, _schoolLon);

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.notAtSchool,
    );
    expect(cubit.state.status, GeofenceCubitStatus.outsideRange);
  });

  test('fake GPS app at the school → fakeLocation, not atSchool', () async {
    await startAtSchoolScreen();
    geolocator.currentPosition = _at(_schoolLat, _schoolLon, mocked: true);

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.fakeLocation,
    );
  });

  test('no GPS fix → locationUnavailable', () async {
    await startAtSchoolScreen();
    geolocator.currentPosition = null;

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.locationUnavailable,
    );
  });

  test('phone Location switched off → gpsOff', () async {
    await startAtSchoolScreen();
    geolocator.serviceEnabled = false;

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.gpsOff,
    );
  });

  test('permission taken away → noPermission', () async {
    await startAtSchoolScreen();
    geolocator.status = LocationPermission.deniedForever;

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.noPermission,
    );
  });

  test('permission granted only now → loads the school, then checks', () async {
    // Denied at screen start, so the school config never loaded.
    geolocator.status = LocationPermission.denied;
    await cubit.initForSchool(schoolCode: 'SCH1');
    expect(cubit.state.status, GeofenceCubitStatus.permissionDenied);

    geolocator
      ..status = LocationPermission.whileInUse
      ..currentPosition = _at(_schoolLat, _schoolLon);

    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.atSchool,
    );
  });

  test('parent GPS sign-in off → gpsSignInOff for parents only', () async {
    repository.config = const GeofenceConfig(
      schoolCode: 'SCH1',
      latitude: _schoolLat,
      longitude: _schoolLon,
      radiusMeters: 200,
      parentGpsSignInEnabled: false,
    );
    await startAtSchoolScreen();

    expect(
      await cubit.checkAtSchoolNow(forParent: true),
      AtSchoolCheck.gpsSignInOff,
    );
    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.atSchool,
    );
  });

  test('no school code → notReady', () async {
    expect(
      await cubit.checkAtSchoolNow(forParent: false),
      AtSchoolCheck.notReady,
    );
  });
}
