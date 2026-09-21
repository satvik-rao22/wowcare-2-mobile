import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/core/utils/app_themes.dart';
import 'package:wowcare/modules/attendance_v2/data/fixtures/staff_overtime_fixtures.dart';
import 'package:wowcare/modules/attendance_v2/presentation/controllers/av2_period.dart';
import 'package:wowcare/modules/attendance_v2/presentation/screens/staff_detail_view.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_detail_scaffold.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/note_style_activity_config.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/note_style_activity_screen.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/notes_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/observation_activity.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

/// Renders the three features brought over from
/// `merge/Staff_overtime_And_observation_activity` and audits what they
/// actually PAINT.
///
/// `centralized_theme_test` reads source text: it proves no file *names* a
/// colour, a font or a gradient. That is not the same as proving the pixels
/// are ours — a widget can still paint an off-palette colour that arrived
/// through a Material default, a `lerp`, or a token composed wrongly. These
/// tests pump each screen inside [AppTheme.light] and walk the built tree.
void main() {
  // ── The legal palette ────────────────────────────────────────────────────
  // Every colour value declared in the one file allowed to declare them.
  // Compared on RGB only: tokens are routinely composed with
  // `withValues(alpha:)`, which is the intended way to soften one.
  final Set<int> paletteRgb = () {
    final String src = File(
      'lib/core/theme/app_theme_config.dart',
    ).readAsStringSync();
    final Set<int> out = <int>{};
    for (final Match m in RegExp(
      r'Color\(0x([0-9A-Fa-f]{8})\)',
    ).allMatches(src)) {
      out.add(int.parse(m.group(1)!, radix: 16) & 0x00FFFFFF);
    }
    for (final Match m in RegExp(
      r'Color\.fromRGBO\(\s*(\d+),\s*(\d+),\s*(\d+),',
    ).allMatches(src)) {
      out.add(
        (int.parse(m.group(1)!) << 16) |
            (int.parse(m.group(2)!) << 8) |
            int.parse(m.group(3)!),
      );
    }
    return out;
  }();

  /// Colours that are not the skin's to own.
  bool isExempt(Color c) {
    if (c.a == 0) return true; // fully transparent: the absence of a colour
    final int rgb = c.toARGB32() & 0x00FFFFFF;
    // Pure black and pure white arrive from Flutter's own scrims, barriers
    // and shadow defaults, which no token controls.
    return rgb == 0x000000 || rgb == 0xFFFFFF;
  }

  /// How many colour-bearing widgets the last audit actually looked at, so a
  /// green result cannot come from a walker that inspected nothing.
  int inspected = 0;

  /// Every colour the built tree paints, with the widget that painted it.
  List<String> offPaletteColours(WidgetTester tester) {
    final List<String> found = <String>[];
    inspected = 0;
    void check(Color? c, String where) {
      if (c != null) inspected++;
      if (c == null || isExempt(c)) return;
      if (!paletteRgb.contains(c.toARGB32() & 0x00FFFFFF)) {
        found.add(
          '$where -> #${(c.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}',
        );
      }
    }

    void checkBorder(BoxBorder? b, String where) {
      if (b is! Border) return;
      for (final BorderSide side in <BorderSide>[
        b.top,
        b.right,
        b.bottom,
        b.left,
      ]) {
        if (side.style != BorderStyle.none) check(side.color, where);
      }
    }

    // Both decoration families the app paints with: Flutter's own, and
    // SkeuDecoration — which is what every AppSurfaces recipe returns, so
    // skipping it would skip exactly the colours the design system owns.
    void checkDecoration(Decoration? d, String where) {
      if (d is BoxDecoration) {
        check(d.color, '$where.color');
        checkBorder(d.border, '$where.border');
        for (final BoxShadow sh in d.boxShadow ?? const <BoxShadow>[]) {
          check(sh.color, '$where.shadow');
        }
      } else if (d is SkeuDecoration) {
        check(d.color, '$where(skeu).color');
        checkBorder(d.border, '$where(skeu).border');
        for (final BoxShadow sh in d.boxShadow) {
          check(sh.color, '$where(skeu).shadow');
        }
      }
    }

    for (final Widget w in tester.allWidgets) {
      final String name = w.runtimeType.toString();
      if (w is DecoratedBox) {
        checkDecoration(w.decoration, '$name.decoration');
      } else if (w is Container) {
        checkDecoration(w.decoration, '$name.decoration');
        check(w.color, '$name.color');
      } else if (w is AnimatedContainer) {
        checkDecoration(w.decoration, '$name.decoration');
      } else if (w is ColoredBox) {
        check(w.color, '$name.color');
      } else if (w is Material) {
        check(w.color, '$name.color');
      } else if (w is Icon) {
        check(w.color, '$name.color');
      } else if (w is Text) {
        check(w.style?.color, '$name("${w.data ?? ''}").style.color');
      }
    }
    return found;
  }

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  // ── 1. Staff overtime detail ─────────────────────────────────────────────
  group('staff overtime detail paints only palette colours', () {
    Widget overtimeHarness({bool canEdit = true}) {
      final profile = StaffOvertimeFixtures.sample;
      return MaterialApp(
        theme: AppTheme.light,
        home: Av2DetailScaffold(
          body: StaffDetailView(
            profile: profile,
            period: Av2Period(
              start: profile.rangeStart,
              end: profile.rangeEnd,
              isWholeMonth: true,
            ),
            loadDetail: (date) async => StaffOvertimeFixtures.dayDetail(date),
            canEdit: canEdit,
            onEditSession:
                ({
                  required recordCode,
                  required signInLocal,
                  signOutLocal,
                }) async {},
            onDeleteSession: (recordCode) async {},
            onEditAbsence:
                ({
                  required code,
                  required fromDate,
                  required toDate,
                  required reason,
                  required type,
                  required note,
                }) async {},
            onDeleteAbsence: (code) async {},
          ),
        ),
      );
    }

    testWidgets('the collapsed day list is on-palette', (tester) async {
      await tester.pumpWidget(overtimeHarness());
      await tester.pumpAndSettle();

      final List<String> off = offPaletteColours(tester);
      // Guard the guard: `find.byType(Widget)` matches only the exact type,
      // so an earlier version of this walk inspected nothing and passed on an
      // injected #123456. Assert it saw a real screen's worth of colour.
      expect(
        inspected,
        greaterThan(50),
        reason: 'The colour walk inspected only $inspected widgets.',
      );
      expect(
        off,
        isEmpty,
        reason:
            'The overtime module was written against the previous palette. '
            'Every colour it paints must now resolve to an AppPalette role '
            'via Av2Colors:\n${off.join('\n')}',
      );
    });

    testWidgets('an expanded day, with its sessions, is on-palette', (
      tester,
    ) async {
      await tester.pumpWidget(overtimeHarness());
      await tester.pumpAndSettle();

      // Open the first attended day so the session tiles, the split bar and
      // the break rows are all built.
      final Finder firstDay = find.byType(InkWell).first;
      await tester.tap(firstDay, warnIfMissed: false);
      await tester.pumpAndSettle();

      final List<String> off = offPaletteColours(tester);
      expect(inspected, greaterThan(50), reason: 'walk saw $inspected');
      expect(off, isEmpty, reason: off.join('\n'));
    });

    testWidgets('surfaces are AppSurfaces recipes, not hand-rolled boxes', (
      tester,
    ) async {
      await tester.pumpWidget(overtimeHarness());
      await tester.pumpAndSettle();

      // AppSurfaces.card()/well() return SkeuDecoration; a plain
      // BoxDecoration on a card-sized box would mean a hand-rolled surface
      // slipped back in.
      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final int skeu = boxes
          .where((b) => b.decoration is SkeuDecoration)
          .length;
      expect(
        skeu,
        greaterThan(0),
        reason:
            'No SkeuDecoration in the tree — the module is not going through '
            'AppSurfaces at all.',
      );
    });
  });

  // ── 2. Observation activity ──────────────────────────────────────────────
  group('observation activity', () {
    test('is the same screen as Notes, differing only by its config', () {
      // The form itself is `NoteStyleActivityScreen`, which is the app's own
      // already-themed Notes screen generalised — so Observation inherits
      // Notes' theming by construction rather than by copy.
      const observation = ObservationActivityScreen();
      const notes = NotesActivityScreen();
      expect(observation.build(_FakeContext()), isA<NoteStyleActivityScreen>());
      expect(notes.build(_FakeContext()), isA<NoteStyleActivityScreen>());

      final obsScreen =
          observation.build(_FakeContext()) as NoteStyleActivityScreen;
      final notesScreen =
          notes.build(_FakeContext()) as NoteStyleActivityScreen;
      expect(obsScreen.config, same(NoteStyleActivityConfig.observation));
      expect(notesScreen.config, same(NoteStyleActivityConfig.notes));
    });

    test('resolves its own activity type, and Notes refuses to claim it', () {
      expect(
        NoteStyleActivityConfig.observation.matchesActivityTypeName(
          'observation',
        ),
        isTrue,
      );
      expect(
        NoteStyleActivityConfig.observation.matchesActivityTypeName(
          'daily observation note',
        ),
        isTrue,
      );
      // The reason the Notes matcher carries an explicit exclusion: an
      // "Observation Note" type would otherwise resolve as Notes.
      expect(
        NoteStyleActivityConfig.notes.matchesActivityTypeName(
          'observation note',
        ),
        isFalse,
      );
      expect(
        NoteStyleActivityConfig.notes.matchesActivityTypeName('daily notes'),
        isTrue,
      );
    });
  });

  // ── 3. Activity sign-in filter ───────────────────────────────────────────
  group('activity sign-in filter toggle', () {
    testWidgets('paints only palette colours in both states', (tester) async {
      for (final bool on in <bool>[false, true]) {
        await tester.pumpWidget(
          host(
            Center(
              child: CustomToggle(
                label: on ? 'Signed In' : 'All Attended',
                isToggled: on,
                labelOnLeftSide: true,
                onToggle: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final List<String> off = offPaletteColours(tester);
        expect(inspected, greaterThan(3), reason: 'walk saw $inspected');
        expect(
          off,
          isEmpty,
          reason: 'toggled=$on painted off-palette:\n${off.join('\n')}',
        );
      }
    });

    testWidgets('is the shared CustomToggle, not a local switch', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Center(
            child: CustomToggle(
              label: 'All Attended',
              isToggled: false,
              labelOnLeftSide: true,
              onToggle: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomToggle), findsOneWidget);
      expect(
        find.byType(Switch),
        findsNothing,
        reason:
            'A bare Material Switch would take Material default colours, not '
            'the skin.',
      );
    });
  });
}

/// `build` on these two wrappers never touches its context, so a stub is
/// enough to read back which config each one hands down.
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} was not expected');
}
