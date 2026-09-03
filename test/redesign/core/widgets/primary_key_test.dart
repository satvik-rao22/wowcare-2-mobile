import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('PrimaryKey', () {
    testWidgets('enabled: shows its label and fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(PrimaryKey(label: 'Sign In', onTap: () => taps++)),
      );

      expect(find.text('Sign In'), findsOneWidget);
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('disabled: draws without a Pressable and ignores taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(PrimaryKey(label: 'Save', enabled: false, onTap: () => taps++)),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(Pressable), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('loading: shows the ring and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PrimaryKey(label: 'Signing in', isLoading: true, onTap: () => taps++),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Signing in'));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('sinks 3px under a press and settles back', (tester) async {
      await tester.pumpWidget(
        _host(PrimaryKey(label: 'Sign In', onTap: () {})),
      );

      double sink() {
        final transform = tester.widget<Transform>(
          find
              .descendant(
                of: find.byType(Pressable),
                matching: find.byType(Transform),
              )
              .first,
        );
        return transform.transform.getTranslation().y;
      }

      expect(sink(), 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Sign In')),
      );
      await tester.pump(AppMotion.press);
      await tester.pump(AppMotion.press);
      expect(sink(), AppSizes.keySink);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(sink(), 0);
    });
  });
}
