import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/domain/features/geofencing/entities/geofence_config.dart';
import 'package:wowcare/domain/features/geofencing/repositories/geofencing_repository.dart';
import 'package:wowcare/domain/features/geofencing/usecases/get_school_location_usecase.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/services/geofence_notification_service.dart';

import '../../../core/util/fake_permission_platforms.dart';

class _FakeRepository implements GeofencingRepository {
  @override
  Future<GeofenceConfig> getSchoolLocation({
    required String schoolCode,
  }) async => const GeofenceConfig(
    schoolCode: 'SCH1',
    latitude: 12.9716,
    longitude: 77.5946,
    radiusMeters: 200,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeNotifications implements GeofenceNotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final logs = <SentryLog>[];
  late FakeGeolocator geolocator;
  late GeofenceCubit cubit;

  setUp(() async {
    logs.clear();
    SharedPreferences.setMockInitialValues({});
    PermissionHandlerPlatform.instance = FakePermissionHandler();
    geolocator = FakeGeolocator();
    GeolocatorPlatform.instance = geolocator;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    cubit = GeofenceCubit(
      getSchoolLocationUseCase: GetSchoolLocationUseCase(_FakeRepository()),
      notificationService: _FakeNotifications(),
    );
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() async {
    await cubit.close();
    await Sentry.close();
    debugDefaultTargetPlatformOverride = null;
  });

  Future<List<SentryLog>> permissionLogs() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return logs
        .where((log) => log.body.startsWith('geofence.permission_request.'))
        .toList();
  }

  test('location granted at the prompt is logged succeeded', () async {
    geolocator.requestResult = LocationPermission.whileInUse;

    await cubit.initForSchool(schoolCode: 'SCH1');

    final log = (await permissionLogs()).single;
    expect(log.body, 'geofence.permission_request.succeeded');
    expect(log.attributes['failure'], isNull);
  });

  test('location denied at the prompt is a permission failure', () async {
    geolocator.requestResult = LocationPermission.deniedForever;

    await cubit.initForSchool(schoolCode: 'SCH1');

    final log = (await permissionLogs()).single;
    expect(log.body, 'geofence.permission_request.failed');
    expect(log.attributes['failure']!.value, 'permission');
    expect(cubit.state.status, GeofenceCubitStatus.permissionDenied);
  });

  test('no prompt, and no event, when location is already allowed', () async {
    geolocator
      ..status = LocationPermission.whileInUse
      ..currentPosition = null;

    await cubit.initForSchool(schoolCode: 'SCH1');

    expect(await permissionLogs(), isEmpty);
    expect(geolocator.requestCount, 0);
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
