import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/segmented_control.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

void main() {
  const c = Colourway.l4;

  group('SegmentedControl', () {
    testWidgets('renders every segment and reports the tapped index', (
      tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          SegmentedControl(
            segments: const <String>['Students', 'Staff'],
            index: 0,
            onChanged: (i) => changed = i,
          ),
        ),
      );

      expect(find.text('Students'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);

      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();
      expect(changed, 1);
    });

    testWidgets('the selected label is ink, the others ink3', (tester) async {
      await tester.pumpWidget(
        _host(
          SegmentedControl(
            segments: const <String>['Day', 'Week', 'Month'],
            index: 2,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      Color? colour(String label) => tester
          .widget<AnimatedDefaultTextStyle>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(AnimatedDefaultTextStyle),
                )
                .first,
          )
          .style
          .color;

      expect(colour('Month'), c.ink);
      expect(colour('Day'), c.ink3);
      expect(colour('Week'), c.ink3);
    });

    testWidgets('shows sublabels under each segment', (tester) async {
      await tester.pumpWidget(
        _host(
          SegmentedControl(
            segments: const <String>['Students', 'Staff'],
            sublabels: const <String>['71 in', '12 in'],
            index: 0,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('71 in'), findsOneWidget);
      expect(find.text('12 in'), findsOneWidget);
    });
  });
}
