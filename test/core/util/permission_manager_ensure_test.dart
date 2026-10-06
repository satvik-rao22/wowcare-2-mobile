import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:wowcare/core/utils/permission_manager.dart';

import 'fake_permission_platforms.dart';

void main() {
  late FakePermissionHandler handler;

  setUp(() {
    handler = FakePermissionHandler();
    PermissionHandlerPlatform.instance = handler;
    GeolocatorPlatform.instance = FakeGeolocator();
    PermissionManager.debugAndroidSdkOverride = 34;
  });

  tearDown(() => PermissionManager.debugAndroidSdkOverride = null);

  /// Pumps a button that runs [PermissionManager.ensure] and returns a getter
  /// for its result (null until the flow finishes).
  Future<bool? Function()> pumpEnsure(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await PermissionManager.ensure(
              context,
              AppPermission.camera,
              reason: 'to scan the QR code',
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('granted: no UI, returns true', (tester) async {
    handler.statuses[Permission.camera] = PermissionStatus.granted;

    final result = await pumpEnsure(tester);

    expect(result(), isTrue);
    expect(find.byType(BottomSheet), findsNothing);
    expect(handler.requestCount, 0);
  });

  testWidgets('first ask: OS dialog only, then true', (tester) async {
    handler.requestResults[Permission.camera] = PermissionStatus.granted;

    final result = await pumpEnsure(tester);

    expect(result(), isTrue);
    expect(handler.requestCount, 1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('user just tapped "Don\'t allow": respected, no nag sheet', (
    tester,
  ) async {
    handler.requestResults[Permission.camera] =
        PermissionStatus.permanentlyDenied;

    final result = await pumpEnsure(tester);

    expect(result(), isFalse);
    expect(find.byType(BottomSheet), findsNothing);
  });

  // Widget tests run as Android unless a variant says otherwise.
  testWidgets(
    'permanently denied: shows steps, "Open Settings" opens Settings',
    (tester) async {
      handler.statuses[Permission.camera] = PermissionStatus.permanentlyDenied;

      final result = await pumpEnsure(tester);

      expect(find.text('Camera access is off'), findsOneWidget);
      expect(
        find.textContaining('WowCare needs camera access to scan the QR code'),
        findsOneWidget,
      );
      expect(find.text('Tap “Permissions”, then “Camera”.'), findsOneWidget);
      expect(handler.requestCount, 0);

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(handler.openSettingsCount, 1);
      expect(result(), isFalse);
    },
  );

  testWidgets(
    'iOS steps use iOS wording',
    (tester) async {
      handler.statuses[Permission.camera] = PermissionStatus.permanentlyDenied;

      await pumpEnsure(tester);

      expect(find.text('Turn on “Camera”.'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('restricted: explains, never offers Settings or asks', (
    tester,
  ) async {
    handler.statuses[Permission.camera] = PermissionStatus.restricted;

    final result = await pumpEnsure(tester);

    expect(find.text('Camera is blocked on this device'), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result(), isFalse);
    expect(handler.requestCount, 0);
  });

  testWidgets(
    'iOS never shows the "explain first" sheet — one refusal is final there',
    (tester) async {
      handler
        ..rationale = true
        ..requestResults[Permission.camera] = PermissionStatus.granted;

      final result = await pumpEnsure(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(handler.requestCount, 1);
      expect(result(), isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  group('Android, refused once before', () {
    setUp(() {
      handler.rationale = true;
      handler.requestResults[Permission.camera] = PermissionStatus.granted;
    });

    testWidgets('explains first, then asks on Continue', (tester) async {
      final result = await pumpEnsure(tester);

      expect(find.text('Allow camera access'), findsOneWidget);
      expect(handler.requestCount, 0);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(handler.requestCount, 1);
      expect(result(), isTrue);
    });

    testWidgets('"Not now" does not ask', (tester) async {
      final result = await pumpEnsure(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(handler.requestCount, 0);
      expect(result(), isFalse);
    });
  });

  group('PermissionBuilder', () {
    Widget app() => MaterialApp(
      home: PermissionBuilder(
        permission: AppPermission.camera,
        builder: (context, status) => Text('$status'),
      ),
    );

    testWidgets('shows the live status', (tester) async {
      handler.statuses[Permission.camera] = PermissionStatus.denied;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('${AppPermissionStatus.denied}'), findsOneWidget);
    });

    testWidgets('re-checks when the app comes back from Settings', (
      tester,
    ) async {
      handler.statuses[Permission.camera] = PermissionStatus.denied;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      handler.statuses[Permission.camera] = PermissionStatus.granted;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('${AppPermissionStatus.granted}'), findsOneWidget);
    });

    testWidgets('re-checks after a request made elsewhere', (tester) async {
      handler.requestResults[Permission.camera] = PermissionStatus.granted;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await PermissionManager.request(AppPermission.camera);
      await tester.pumpAndSettle();

      expect(find.text('${AppPermissionStatus.granted}'), findsOneWidget);
    });
  });
}
