import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:wowcare/core/utils/permission_manager.dart';

import 'fake_permission_platforms.dart';

void main() {
  late FakePermissionHandler handler;
  late FakeGeolocator geolocator;

  setUp(() {
    handler = FakePermissionHandler();
    geolocator = FakeGeolocator();
    PermissionHandlerPlatform.instance = handler;
    GeolocatorPlatform.instance = geolocator;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    PermissionManager.debugAndroidSdkOverride = 34;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PermissionManager.debugAndroidSdkOverride = null;
  });

  group('status', () {
    test('maps every plugin status to the four app states', () async {
      const expected = {
        PermissionStatus.granted: AppPermissionStatus.granted,
        PermissionStatus.limited: AppPermissionStatus.granted,
        PermissionStatus.provisional: AppPermissionStatus.granted,
        PermissionStatus.denied: AppPermissionStatus.denied,
        PermissionStatus.permanentlyDenied:
            AppPermissionStatus.permanentlyDenied,
        PermissionStatus.restricted: AppPermissionStatus.restricted,
      };
      for (final entry in expected.entries) {
        handler.statuses[Permission.camera] = entry.key;
        expect(
          await PermissionManager.status(AppPermission.camera),
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    test('a plugin failure reads as denied instead of throwing', () async {
      handler.throwOnCheck = Exception('channel gone');
      expect(
        await PermissionManager.status(AppPermission.camera),
        AppPermissionStatus.denied,
      );
    });

    test(
      'iOS location comes from Geolocator, not permission_handler',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        // permission_handler would say denied: PERMISSION_LOCATION is unset.
        handler.statuses[Permission.locationWhenInUse] =
            PermissionStatus.denied;
        geolocator.status = LocationPermission.whileInUse;

        expect(
          await PermissionManager.status(AppPermission.location),
          AppPermissionStatus.granted,
        );
      },
    );

    test('Android location comes from permission_handler', () async {
      handler.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;
      geolocator.status = LocationPermission.denied;

      expect(
        await PermissionManager.status(AppPermission.location),
        AppPermissionStatus.granted,
      );
    });

    test('Android 12 notifications off = Settings-only, not askable', () async {
      PermissionManager.debugAndroidSdkOverride = 32;
      handler.statuses[Permission.notification] = PermissionStatus.denied;

      expect(
        await PermissionManager.status(AppPermission.notifications),
        AppPermissionStatus.permanentlyDenied,
      );
    });

    test('Android 13 notifications denied stays askable', () async {
      handler.statuses[Permission.notification] = PermissionStatus.denied;

      expect(
        await PermissionManager.status(AppPermission.notifications),
        AppPermissionStatus.denied,
      );
    });
  });

  group('request', () {
    test('does not show the OS dialog when already granted', () async {
      handler.statuses[Permission.camera] = PermissionStatus.granted;

      expect(
        await PermissionManager.request(AppPermission.camera),
        AppPermissionStatus.granted,
      );
      expect(handler.requestCount, 0);
    });

    test('does not ask when restricted — nobody can answer it', () async {
      handler.statuses[Permission.camera] = PermissionStatus.restricted;

      expect(
        await PermissionManager.request(AppPermission.camera),
        AppPermissionStatus.restricted,
      );
      expect(handler.requestCount, 0);
    });

    test('returns what the OS dialog answered', () async {
      handler.requestResults[Permission.camera] = PermissionStatus.granted;

      expect(
        await PermissionManager.request(AppPermission.camera),
        AppPermissionStatus.granted,
      );
      expect(handler.requestCount, 1);
    });

    test('queues concurrent requests instead of overlapping them', () async {
      handler.requestDelay = const Duration(milliseconds: 20);
      handler.requestResults[Permission.camera] = PermissionStatus.granted;

      final results = await Future.wait([
        PermissionManager.request(AppPermission.camera),
        PermissionManager.request(AppPermission.camera),
      ]);

      expect(results, everyElement(AppPermissionStatus.granted));
      // The second call waited, saw "granted", and skipped the dialog.
      expect(handler.requestCount, 1);
    });

    test('notifies listeners so on-screen builders re-check', () async {
      var notified = 0;
      void listener() => notified++;
      PermissionManager.changes.addListener(listener);
      addTearDown(() => PermissionManager.changes.removeListener(listener));

      await PermissionManager.request(AppPermission.camera);

      expect(notified, 1);
    });
  });

  test('isLocationServiceEnabled reports the GPS switch', () async {
    geolocator.serviceEnabled = false;
    expect(await PermissionManager.isLocationServiceEnabled(), isFalse);

    geolocator.serviceEnabled = true;
    expect(await PermissionManager.isLocationServiceEnabled(), isTrue);
  });
}
