import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_pin_pad_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';

const String _tap = 'HapticFeedbackType.lightImpact';
const String _select = 'HapticFeedbackType.selectionClick';
const String _success = 'HapticFeedbackType.successNotification';
const String _warning = 'HapticFeedbackType.warningNotification';
const String _error = 'HapticFeedbackType.errorNotification';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every haptic type the app asked the platform for, in order.
  final List<Object?> played = <Object?>[];

  void mockPlatform(Future<Object?>? Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, handler);
  }

  setUp(() {
    played.clear();
    mockPlatform((MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') played.add(call.arguments);
      return null;
    });
  });

  tearDown(() => mockPlatform(null));

  Future<void> pumpIn(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('AppHaptics', () {
    test('each moment plays its own platform feedback type', () async {
      AppHaptics.tap();
      AppHaptics.select();
      AppHaptics.success();
      AppHaptics.warning();
      AppHaptics.error();
      await pumpEventQueue();

      expect(played, <String>[_tap, _select, _success, _warning, _error]);
    });

    test('a platform that rejects the call never breaks the caller', () async {
      mockPlatform((MethodCall call) async {
        throw PlatformException(code: 'no-haptics');
      });

      AppHaptics.tap();
      await pumpEventQueue();
    });

    test('a platform with no haptics handler stays silent too', () async {
      mockPlatform(null);

      AppHaptics.error();
      await pumpEventQueue();
    });
  });

  group('shared controls answer a press', () {
    testWidgets('a confirm button taps once per press', (tester) async {
      int presses = 0;
      await pumpIn(
        tester,
        CustomConfirmButton(label: 'Save', onPressed: () => presses++),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(presses, 1);
      expect(played, <String>[_tap]);
    });

    testWidgets('a disabled confirm button stays silent', (tester) async {
      await pumpIn(
        tester,
        const CustomConfirmButton(label: 'Save', onPressed: null),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(played, isEmpty);
    });

    testWidgets('a cancel button taps and still runs its action', (
      tester,
    ) async {
      int presses = 0;
      await pumpIn(
        tester,
        CustomCancelButton(onPressedCancel: () => presses++),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(presses, 1);
      expect(played, <String>[_tap]);
    });

    testWidgets('a toggle clicks as it flips, and not while locked', (
      tester,
    ) async {
      final List<bool> values = <bool>[];
      Widget toggle({required bool enabled}) => CustomToggle(
        label: 'Signed in',
        isToggled: false,
        enabled: enabled,
        onToggle: values.add,
      );
      Finder track() => find.descendant(
        of: find.byType(CustomToggle),
        matching: find.byType(GestureDetector),
      );

      await pumpIn(tester, toggle(enabled: true));
      await tester.tap(track());
      await tester.pump();
      expect(values, <bool>[true]);
      expect(played, <String>[_select]);

      await pumpIn(tester, toggle(enabled: false));
      await tester.tap(track());
      await tester.pump();
      expect(played, <String>[_select]);
    });

    testWidgets('a disabled add button reports the tap but stays silent', (
      tester,
    ) async {
      int taps = 0;
      await pumpIn(tester, GradientAddButton(onTap: () => taps++));
      await tester.tap(find.byType(GradientAddButton));
      await tester.pump();
      expect(played, <String>[_tap]);

      await pumpIn(
        tester,
        GradientAddButton(onTap: () => taps++, isDisabled: true),
      );
      await tester.tap(find.byType(GradientAddButton));
      await tester.pump();

      expect(taps, 2);
      expect(played, <String>[_tap]);
    });

    testWidgets('the PIN pad taps only when a key changes the PIN', (
      tester,
    ) async {
      await pumpIn(
        tester,
        KioskPinPadWidget(
          isLogout: true,
          maxPinLength: 1,
          onPinSubmit: (String pin, {bool isLogout = false}) async {},
        ),
      );
      final Finder backspace = find.byIcon(Icons.backspace_outlined);

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2')); // Past the max length: ignored.
      await tester.tap(backspace);
      await tester.tap(backspace); // Nothing left to delete.
      await tester.pump();

      expect(played, <String>[_tap, _tap]);
    });
  });

  group('banners buzz with their colour', () {
    Future<void> show(
      WidgetTester tester, {
      bool isError = false,
      bool isWarning = false,
      bool isSuccess = false,
    }) async {
      await pumpIn(tester, const SizedBox());
      CoreUtils.showTopSnackBar(
        context: tester.element(find.byType(Scaffold)),
        message: 'Saved',
        isError: isError,
        isWarning: isWarning,
        isSuccess: isSuccess,
      );
      await tester.pump();
      // Let the banner's removal timer run out before the test ends.
      await tester.pump(const Duration(seconds: 5));
    }

    testWidgets('red plays error', (tester) async {
      await show(tester, isError: true);
      expect(played, <String>[_error]);
    });

    testWidgets('orange plays warning', (tester) async {
      await show(tester, isWarning: true);
      expect(played, <String>[_warning]);
    });

    testWidgets('green and plain banners stay silent', (tester) async {
      await show(tester, isSuccess: true);
      await show(tester);
      expect(played, isEmpty);
    });
  });
}
