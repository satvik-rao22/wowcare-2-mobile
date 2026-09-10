import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Guards the flat skeuomorphic material itself: the two primitives ported
/// from `wowcare-skeumorph`, and the decoration builders every module will
/// call.
///
/// The invariant that matters most is the first group. If a fill here ever
/// grows a second stop, the re-skin has failed at the foundation.
void main() {
  group('nothing in the material is a gradient', () {
    test('SkeuDecoration cannot express one', () {
      // Not a style choice — there is no field to put one in. A call site
      // that wants a gradient has to leave AppSurfaces to get it, which is
      // what the allowlist in centralized_theme_test.dart catches.
      expect(const SkeuDecoration().toString(), isNot(contains('Gradient')));
    });

    test('every builder paints one flat colour', () {
      final Map<String, SkeuDecoration> all = <String, SkeuDecoration>{
        'card': AppSurfaces.card(),
        'panel': AppSurfaces.panel(),
        'impact': AppSurfaces.impact(),
        'toast': AppSurfaces.toast(),
        'sub': AppSurfaces.sub(),
        'tray': AppSurfaces.tray(),
        'bar': AppSurfaces.bar(),
        'sheet': AppSurfaces.sheet(),
        'well': AppSurfaces.well(),
        'field': AppSurfaces.field(),
        'trough': AppSurfaces.trough(),
        'segmented': AppSurfaces.segmented(),
        'segmentSelected': AppSurfaces.segmentSelected(),
        'iconKey': AppSurfaces.iconKey(),
        'fab': AppSurfaces.fab(),
        'fabDead': AppSurfaces.fab(enabled: false),
        'chip': AppSurfaces.chip(),
        'chipSelected': AppSurfaces.chipSelected(),
        'knob': AppSurfaces.knob(),
        'navActive': AppSurfaces.navActive(),
        'emptyIcon': AppSurfaces.emptyIcon(),
        for (final KeyVariant v in KeyVariant.values)
          'key.${v.name}': AppSurfaces.key(v),
        for (final AppTone t in AppTone.values)
          'pill.${t.name}': AppSurfaces.pill(t),
        for (final AppTone t in AppTone.values)
          'avatar.${t.name}': AppSurfaces.avatar(t),
      };

      for (final MapEntry<String, SkeuDecoration> e in all.entries) {
        expect(e.value.color, isNotNull, reason: '${e.key} has no fill');
      }
    });

    test('pure white and pure black are retired from every fill', () {
      const int white = 0xFFFFFFFF;
      const int black = 0xFF000000;
      for (final SkeuDecoration d in <SkeuDecoration>[
        AppSurfaces.card(),
        AppSurfaces.sub(),
        AppSurfaces.tray(),
        AppSurfaces.well(),
        AppSurfaces.impact(),
        AppSurfaces.key(KeyVariant.primary),
        AppSurfaces.key(KeyVariant.secondary),
      ]) {
        expect(d.color!.toARGB32(), isNot(white));
        expect(d.color!.toARGB32(), isNot(black));
      }
    });
  });

  group('the grammar: raised bevels up, wells cut in', () {
    test('a card is lit on its top edge and casts a shadow below', () {
      final SkeuDecoration card = AppSurfaces.card();
      expect(card.insets.single.offset.dy, 1, reason: 'bevel on the top edge');
      expect(card.boxShadow.single.offset.dy, greaterThan(0));
      expect(card.color, AppPalette.surfaceCard);
      expect(card.border, Border.all(color: AppPalette.borderHairline));
    });

    test('a well throws its shadow inward from the top and casts none', () {
      final SkeuDecoration well = AppSurfaces.well();
      expect(well.boxShadow, isEmpty, reason: 'recessed things do not float');
      expect(well.insets.first.offset.dy, greaterThan(0));
      expect(well.insets.first.blur, greaterThan(0));
      expect(well.color, AppPalette.surfaceField);
    });

    test('a field is a shallower well than a dropdown', () {
      expect(
        AppSurfaces.field().insets.first.blur,
        lessThan(AppSurfaces.well().insets.first.blur),
      );
    });

    test('an error field gains the danger edge and nothing else moves', () {
      final SkeuDecoration plain = AppSurfaces.field();
      final SkeuDecoration bad = AppSurfaces.field(error: true);
      expect(bad.border, Border.all(color: AppPalette.statusError, width: 1.5));
      expect(bad.color, plain.color);
      expect(bad.insets, plain.insets);
    });

    test('a sheet throws its shadow upward, onto what it covers', () {
      expect(AppSurfaces.sheet().boxShadow.single.offset.dy, lessThan(0));
      expect(AppSurfaces.bar().boxShadow.single.offset.dy, lessThan(0));
    });

    test('an impact card is navy with a warm-white gloss', () {
      final SkeuDecoration impact = AppSurfaces.impact();
      expect(impact.color, AppPalette.surfaceInverse);
      expect(impact.insets.single.color.toARGB32() >> 24, lessThan(0xFF));
      expect(
        impact.insets.single.color.withValues(alpha: 1),
        AppPalette.bevelGloss,
      );
    });
  });

  group('keys sit on a rim you press away', () {
    test('the recommended key is pink on a pink rim', () {
      final SkeuDecoration k = AppSurfaces.key(KeyVariant.primary);
      expect(k.color, AppPalette.brand);
      expect(k.boxShadow.first.color, AppPalette.rimAction);
      expect(k.boxShadow.first.offset.dy, AppElevation.rimDepth);
      expect(k.boxShadow.first.blurRadius, 0, reason: 'a rim is not a blur');
      expect(AppSurfaces.keyInk(KeyVariant.primary), AppPalette.onBrand);
    });

    test('pressing collapses the rim to 1px, so the face lands on it', () {
      final SkeuDecoration rest = AppSurfaces.key(KeyVariant.primary);
      final SkeuDecoration down = AppSurfaces.keyPressed(KeyVariant.primary);
      expect(down.boxShadow.single.offset.dy, AppElevation.rimDepthPressed);
      expect(
        rest.boxShadow.first.offset.dy - down.boxShadow.single.offset.dy,
        AppMotion.pressTravel,
        reason: 'the sink and the rim collapse must be the same distance',
      );
    });

    test('a disabled key is recessed and rimless, not hidden', () {
      final SkeuDecoration k = AppSurfaces.key(KeyVariant.disabled);
      expect(k.boxShadow, isEmpty, reason: 'no rim: it reads flat and dead');
      expect(k.insets, isNotEmpty);
      expect(k.color, AppPalette.surfaceField);
    });

    test('a dead FAB is a well and stays in place', () {
      final SkeuDecoration dead = AppSurfaces.fab(enabled: false);
      expect(dead.color, AppPalette.surfaceField);
      expect(dead.boxShadow, isEmpty);
      expect(dead.insets, AppElevation.fabDead);
    });

    test('every key variant has a legible ink', () {
      for (final KeyVariant v in KeyVariant.values) {
        expect(AppSurfaces.keyInk(v), isNotNull);
      }
    });
  });

  group('tones carry meaning, and always bring their own ink', () {
    test('a fill never comes without a matching text colour', () {
      for (final AppTone t in AppTone.values) {
        expect(t.fill, isNot(t.ink), reason: '${t.name} would be invisible');
        expect(t.solid, isNotNull);
      }
    });

    test('teal means child and sun means staff, and they differ', () {
      expect(AppTone.student.fill, BrandRamps.tealTint);
      expect(AppTone.staff.fill, BrandRamps.sunTint);
      expect(AppTone.student.fill, isNot(AppTone.staff.fill));
    });
  });

  group(
    'SkeuDecoration substitutes for BoxDecoration without moving content',
    () {
      test('padding matches a BoxDecoration with the same border', () {
        const Border ring = Border.fromBorderSide(BorderSide(width: 1.5));
        expect(
          const SkeuDecoration(border: ring).padding,
          const BoxDecoration(border: ring).padding,
        );
        expect(const SkeuDecoration().padding, EdgeInsets.zero);
      });

      test('a bar is lit only on the edge facing the content it covers', () {
        final Border border = AppSurfaces.bar().border! as Border;
        expect(border.top.color, AppPalette.borderHairline);
        expect(border.bottom, BorderSide.none);
      });

      test('a key with no rim does not fake one when pressed', () {
        // A secondary key has no rim to collapse, so pressing it pulls its
        // ambient shadow in close instead — the surface reading as pushed
        // toward the ground rather than sprouting a rim it never had.
        final SkeuDecoration rest = AppSurfaces.key(KeyVariant.secondary);
        final SkeuDecoration down = AppSurfaces.keyPressed(
          KeyVariant.secondary,
        );
        expect(down.color, rest.color);
        expect(down.boxShadow, AppElevation.cardPressed);
        expect(
          down.boxShadow.first.offset.dy,
          lessThan(rest.boxShadow.first.offset.dy),
        );

        // A disabled key does not respond at all.
        expect(
          AppSurfaces.keyPressed(KeyVariant.disabled),
          AppSurfaces.key(KeyVariant.disabled),
        );
      });

      test('hit-testing follows the rounded shape', () {
        const SkeuDecoration d = SkeuDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        );
        expect(d.hitTest(const Size(100, 100), const Offset(50, 50)), isTrue);
        expect(d.hitTest(const Size(100, 100), const Offset(1, 1)), isFalse);
      });

      test('equal recipes compare equal, so repaints are skipped', () {
        expect(AppSurfaces.card(), AppSurfaces.card());
        expect(AppSurfaces.card().hashCode, AppSurfaces.card().hashCode);
        expect(AppSurfaces.card(), isNot(AppSurfaces.impact()));
      });

      test('it lerps to another of its own kind', () {
        final Decoration? mid = Decoration.lerp(
          AppSurfaces.card(),
          AppSurfaces.impact(),
          .5,
        );
        expect(mid, isA<SkeuDecoration>());
        expect(
          (mid! as SkeuDecoration).color,
          Color.lerp(AppPalette.surfaceCard, AppPalette.surfaceInverse, .5),
        );
      });

      testWidgets('it paints without throwing, at any size', (
        WidgetTester tester,
      ) async {
        for (final SkeuDecoration d in <SkeuDecoration>[
          AppSurfaces.card(),
          AppSurfaces.well(),
          AppSurfaces.key(KeyVariant.primary),
          AppSurfaces.avatar(AppTone.student),
          AppSurfaces.sheet(),
        ]) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: DecoratedBox(
                  decoration: d,
                  child: const SizedBox(width: 120, height: 48),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        }
      });
    },
  );

  group('SkeuPressable', () {
    double sinkOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(SkeuPressable),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .y;

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

    testWidgets('sinks the same 2px whatever the child size', (
      WidgetTester tester,
    ) async {
      final List<double> sinks = <double>[];

      for (final double height in <double>[40, 400]) {
        await pumpPressable(tester, height);
        expect(sinkOf(tester), 0, reason: 'must rest flush before the press');

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byType(SkeuPressable)),
        );
        await tester.pumpAndSettle();
        sinks.add(sinkOf(tester));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(sinkOf(tester), 0, reason: 'must settle back after release');
      }

      // The bug this replaces: a fractional offset made the sink proportional
      // to the child, so a tall card sank far further than a row.
      expect(sinks, <double>[
        AppMotion.pressTravelSurface,
        AppMotion.pressTravelSurface,
      ]);
    });

    testWidgets('a key sinks 3px and does not scale', (
      WidgetTester tester,
    ) async {
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

      expect(sinkOf(tester), AppMotion.pressTravel);
      // Only the translate Transform, with no scale one nested inside it.
      expect(
        find.descendant(
          of: find.byType(SkeuPressable),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
    });

    testWidgets('fires onTap, and stays inert without a handler', (
      WidgetTester tester,
    ) async {
      int taps = 0;
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

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkeuPressable.surface(
                child: SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.startGesture(tester.getCenter(find.byType(SkeuPressable)));
      await tester.pumpAndSettle();
      expect(sinkOf(tester), 0, reason: 'nothing to press, so nothing sinks');
    });
  });
}
