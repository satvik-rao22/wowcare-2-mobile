import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/widgets/geofence_sign_in_check.dart';

import '../../../core/util/fake_permission_platforms.dart';

/// Only [checkAtSchoolNow] matters here; everything else is a no-op.
class _FakeGeofenceCubit extends Cubit<GeofenceState> implements GeofenceCubit {
  _FakeGeofenceCubit() : super(const GeofenceState.initial());

  AtSchoolCheck result = AtSchoolCheck.atSchool;
  int checks = 0;

  @override
  Future<AtSchoolCheck> checkAtSchoolNow({required bool forParent}) async {
    checks++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late FakePermissionHandler handler;
  late _FakeGeofenceCubit cubit;

  setUp(() {
    handler = FakePermissionHandler();
    PermissionHandlerPlatform.instance = handler;
    GeolocatorPlatform.instance = FakeGeolocator();
    cubit = _FakeGeofenceCubit();
  });

  tearDown(() => cubit.close());

  /// Taps a button that runs [confirmAtSchool]; returns its result getter.
  Future<bool? Function()> tapSignIn(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GeofenceCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await confirmAtSchool(context, forParent: false),
                child: const Text('Sign-In'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Sign-In'));
    await tester.pumpAndSettle();
    return () => result;
  }

  /// Lets the top banner's dismiss timer run out.
  Future<void> flushBanner(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  testWidgets('allowed and at school → continues, no message', (tester) async {
    handler.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;

    final result = await tapSignIn(tester);

    expect(result(), isTrue);
    expect(cubit.checks, 1);
    expect(find.text('Checking your location...'), findsNothing);
    expect(find.textContaining('not at school'), findsNothing);
  });

  testWidgets('not at school → stops and says why', (tester) async {
    handler.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;
    cubit.result = AtSchoolCheck.notAtSchool;

    final result = await tapSignIn(tester);

    expect(result(), isFalse);
    expect(
      find.text('You are not at school. Move closer to the school to sign in.'),
      findsOneWidget,
    );
    await flushBanner(tester);
  });

  testWidgets('not asked yet → asks, then checks once granted', (tester) async {
    handler.requestResults[Permission.locationWhenInUse] =
        PermissionStatus.granted;

    final result = await tapSignIn(tester);

    expect(handler.requestCount, 1);
    expect(cubit.checks, 1);
    expect(result(), isTrue);
  });

  testWidgets('user says no to the dialog → no location check', (tester) async {
    final result = await tapSignIn(tester);

    expect(handler.requestCount, 1);
    expect(cubit.checks, 0);
    expect(result(), isFalse);
  });

  testWidgets('permanently denied → Settings steps, no location check', (
    tester,
  ) async {
    handler.statuses[Permission.locationWhenInUse] =
        PermissionStatus.permanentlyDenied;

    await tapSignIn(tester);

    expect(find.text('Location access is off'), findsOneWidget);
    expect(
      find.textContaining('to check that you are at school'),
      findsOneWidget,
    );
    expect(cubit.checks, 0);
  });

  test('every message survives the warning-banner sanitizer unchanged', () {
    for (final result in AtSchoolCheck.values) {
      final message = atSchoolMessage(result, 'sign in');
      if (message == null) continue;
      expect(
        ApiErrorHandler.sanitizeMessage(message),
        message,
        reason: '$result',
      );
    }
  });
}
