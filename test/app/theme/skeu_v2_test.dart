import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// Guards the three things v2 of the design changed in the shared skeuomorphic
/// layer: surfaces are flat, every press sinks the same fixed distance, and the
/// segmented switcher slides rather than teleports.
void main() {
  group('flat pass', () {
    test('every surface token paints a single colour', () {
      const surfaces = <String, Gradient>{
        'page': SkeuSurfaces.page,
        'card': SkeuSurfaces.card,
        'raised': SkeuSurfaces.raised,
        'sunken': SkeuSurfaces.sunken,
        'field': SkeuSurfaces.field,
        'navy': SkeuSurfaces.navy,
        'rail': SkeuSurfaces.rail,
        'tealSoft': SkeuSurfaces.tealSoft,
        'pinkSoft': SkeuSurfaces.pinkSoft,
        'sunSoft': SkeuSurfaces.sunSoft,
        'greenSoft': SkeuSurfaces.greenSoft,
        'orangeSoft': SkeuSurfaces.orangeSoft,
        'purpleSoft': SkeuSurfaces.purpleSoft,
        'facePink': SkeuSurfaces.facePink,
        'faceTeal': SkeuSurfaces.faceTeal,
        'faceSun': SkeuSurfaces.faceSun,
        'faceGreen': SkeuSurfaces.faceGreen,
        'faceOrange': SkeuSurfaces.faceOrange,
        'faceNavy': SkeuSurfaces.faceNavy,
        'faceNeutral': SkeuSurfaces.faceNeutral,
      };

      for (final entry in surfaces.entries) {
        expect(
          entry.value.colors.toSet(),
          hasLength(1),
          reason: '${entry.key} still has more than one colour stop',
        );
      }
    });

    test('gloss is gone', () {
      for (final gloss in [SkeuSurfaces.glossTop, SkeuSurfaces.glossSheen]) {
        for (final c in gloss.colors) {
          expect(c.a, 0, reason: 'gloss must be fully transparent');
        }
      }
    });

    test('every rimmed key variant has a flat face', () {
      for (final variant in SkeuButtonVariant.values) {
        expect(
          skeuKeySkin(variant).face.colors.toSet(),
          hasLength(1),
          reason: '$variant still has a gradient face',
        );
      }
    });

    test('the brand rail is four equal hard bands, not a blend', () {
      // Hard stops come in pairs, so each colour holds a quarter of the width.
      expect(SkeuSurfaces.railBrand.stops, [0, .25, .25, .5, .5, .75, .75, 1]);
      expect(SkeuSurfaces.railBrand.colors, [
        SkeuColors.pink500,
        SkeuColors.pink500,
        SkeuColors.sun400,
        SkeuColors.sun400,
        SkeuColors.teal500,
        SkeuColors.teal500,
        SkeuColors.green500,
        SkeuColors.green500,
      ]);
    });
  });

  group('SkeuPressable', () {
    /// The y translation the pressable is currently applying to its child.
    double sinkOf(WidgetTester tester) {
      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(SkeuPressable),
              matching: find.byType(Transform),
            )
            .first,
      );
      return transform.transform.getTranslation().y;
    }

    Future<void> pumpPressable(WidgetTester tester, double childHeight) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SkeuPressable.surface(
                  onTap: () {},
                  child: SizedBox(width: 200, height: childHeight),
                ),
              ),
            ),
          ),
        );

    testWidgets('sinks the same 2px whatever the child size', (tester) async {
      final sinks = <double>[];

      for (final height in [40.0, 400.0]) {
        await pumpPressable(tester, height);
        expect(sinkOf(tester), 0, reason: 'must rest flush before the press');

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SkeuPressable)),
        );
        // Let the 90ms press animation run to completion.
        await tester.pumpAndSettle();
        sinks.add(sinkOf(tester));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(sinkOf(tester), 0, reason: 'must settle back after release');
      }

      // This is the v1 bug the design called out: a fractional offset made the
      // sink proportional to the child, so a tall card sank far further.
      expect(sinks, [2, 2]);
    });

    testWidgets('a key sinks 3px and does not scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkeuPressable.key(
                onTap: () {},
                child: const SizedBox(width: 120, height: 48),
              ),
            ),
          ),
        ),
      );

      await tester.startGesture(tester.getCenter(find.byType(SkeuPressable)));
      await tester.pumpAndSettle();

      expect(sinkOf(tester), 3);
      // Only the translate Transform, no scale one nested inside it.
      expect(
        find.descendant(
          of: find.byType(SkeuPressable),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
    });

    testWidgets('fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkeuPressable.surface(
                onTap: () => taps++,
                child: const SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SkeuPressable));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('SkeuSegmentedTabs', () {
    Future<void> pumpTabs(
      WidgetTester tester,
      int selected,
      ValueChanged<int> onChanged,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SkeuSegmentedTabs(
                labels: const ['Students', 'Staff', 'Notes'],
                selectedIndex: selected,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );

    /// The indicator is the only DecoratedBox carrying the teal key face.
    Rect indicatorRect(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(SkeuSegmentedTabs),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );

    testWidgets('the indicator slides instead of teleporting', (tester) async {
      await pumpTabs(tester, 0, (_) {});
      await tester.pumpAndSettle();
      final start = indicatorRect(tester).left;

      await pumpTabs(tester, 2, (_) {});
      await tester.pump(); // start the transition
      await tester.pump(const Duration(milliseconds: 80));
      final middle = indicatorRect(tester).left;

      await tester.pumpAndSettle();
      final end = indicatorRect(tester).left;

      expect(end, greaterThan(start), reason: 'it should end further right');
      expect(middle, greaterThan(start), reason: 'it should have begun moving');
      expect(
        middle,
        lessThan(end),
        reason: 'it should still be in flight, not already arrived',
      );
    });

    testWidgets('reports the tapped segment', (tester) async {
      final tapped = <int>[];
      await pumpTabs(tester, 0, tapped.add);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(tapped, [2]);
    });
  });

  group('SkeuFab', () {
    /// The FAB's icon, measured in global coordinates, so every transform the
    /// entrance applies shows up in the rect. Deliberately not reading the
    /// Transform widgets by index — that couples the test to the widget tree.
    Rect iconRect(WidgetTester tester) => tester.getRect(
      find.descendant(of: find.byType(SkeuFab), matching: find.byType(Icon)),
    );

    testWidgets('plays fabIn: rises, overshoots, then settles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuFabDock(
              fab: SkeuFab(icon: Icons.add_rounded, onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pump();
      final first = iconRect(tester);

      // 62% of 560ms is the overshoot peak.
      await tester.pump(const Duration(milliseconds: 347));
      final peak = iconRect(tester);

      await tester.pump(const Duration(milliseconds: 250));
      final settled = iconRect(tester);

      expect(
        first.width,
        lessThan(settled.width * 0.5),
        reason: 'it should start scaled right down',
      );
      expect(
        peak.width,
        greaterThan(settled.width),
        reason: 'the spring should overshoot past full size',
      );
      expect(
        first.center.dy,
        greaterThan(settled.center.dy + 20),
        reason: 'it should start ~26px below its resting place',
      );
      expect(
        peak.center.dy,
        closeTo(settled.center.dy, 1),
        reason: 'the rise should be done by the overshoot peak',
      );
    });

    testWidgets('fires onTap and disposes its timers cleanly', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuFabDock(
              fab: SkeuFab(icon: Icons.add_rounded, onTap: () => taps++),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(SkeuFab));
      await tester.pump();
      expect(taps, 1);

      // The breathing glow schedules a delayed start; tearing the tree down
      // before it fires must not leave a pending timer behind.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
    });

    testWidgets('the confirmation pops in above the key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeuFabDock(
              confirmation: const SkeuFabConfirmation(label: 'Student added'),
              fab: SkeuFab(icon: Icons.add_rounded, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Student added'), findsOneWidget);
      // It sits above the key, as the design stacks them.
      expect(
        tester.getCenter(find.text('Student added')).dy,
        lessThan(tester.getCenter(find.byType(SkeuFab)).dy),
      );

      await tester.pump(const Duration(milliseconds: 500));
      final settled = tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(SkeuFabConfirmation),
                  matching: find.byType(Transform),
                )
                .at(1),
          )
          .transform;
      expect(settled.getMaxScaleOnAxis(), closeTo(1, 0.01));
    });
  });
}
