import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_toggle.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const c = Colourway.l4;

  group('AppToggle', () {
    testWidgets('is 46 by 27 and flips on tap', (tester) async {
      bool? changed;
      await tester.pumpWidget(
        _host(AppToggle(value: false, onChanged: (v) => changed = v)),
      );

      final size = tester.getSize(find.byType(AppToggle));
      expect(size.width, AppSizes.toggleWidth);
      expect(size.height, AppSizes.toggleHeight);

      await tester.tap(find.byType(AppToggle));
      expect(changed, isTrue);
    });

    testWidgets('on is green, off is the well', (tester) async {
      Color? trackColour() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration)
              .color;

      await tester.pumpWidget(_host(AppToggle(value: true, onChanged: (_) {})));
      expect(trackColour(), c.success);

      await tester.pumpWidget(
        _host(AppToggle(value: false, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(trackColour(), c.track);
    });

    testWidgets('the knob sits right when on and left when off', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AppToggle(value: true, onChanged: (_) {})));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment,
        Alignment.centerRight,
      );

      await tester.pumpWidget(
        _host(AppToggle(value: false, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment,
        Alignment.centerLeft,
      );
    });

    testWidgets('inert without onChanged', (tester) async {
      await tester.pumpWidget(
        _host(const AppToggle(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(AppToggle));
      await tester.pumpAndSettle();
      expect(find.byType(AppToggle), findsOneWidget);
    });
  });
}
