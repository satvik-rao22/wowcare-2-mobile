import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_v2/data/fixtures/staff_overtime_fixtures.dart';
import 'package:wowcare/modules/attendance_v2/presentation/controllers/av2_day_filter.dart';
import 'package:wowcare/modules/attendance_v2/presentation/controllers/av2_period.dart';
import 'package:wowcare/modules/attendance_v2/presentation/screens/staff_detail_view.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_detail_scaffold.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_split_bar.dart';

Widget _harness({bool canEdit = true}) {
  final profile = StaffOvertimeFixtures.sample;
  return MaterialApp(
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
        onEditSession: ({
          required recordCode,
          required signInLocal,
          signOutLocal,
        }) async {},
        onDeleteSession: (recordCode) async {},
        onEditAbsence: ({
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

void main() {
  final sizes = <String, Size>{
    'mobile-small': const Size(320, 720),
    'mobile': const Size(390, 844),
    'tablet': const Size(768, 1024),
    'desktop': const Size(1440, 900),
  };

  for (final entry in sizes.entries) {
    testWidgets('renders without overflow at ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = entry.value;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Devi Vempati'), findsOneWidget);
      // Hero legend (plain Text) confirms the summary card rendered.
      expect(find.text('Regular (64h)'), findsOneWidget);
    });
  }

  testWidgets('filter chips switch the list and find absent day', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // The chip is first in the tree (before the timeline pills).
    await tester.tap(find.text(Av2DayFilter.absent.label).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Absent'), findsWidgets);
  });

  testWidgets('expanding a day reveals its sessions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // The needs-attention day (Jun 11) auto-expands; its first session is in
    // the Office classroom and shows both the in-by and out-by names.
    expect(find.text('Office'), findsWidgets);
    expect(find.textContaining('by Spandana'), findsWidgets);
    expect(find.textContaining('by System'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('break intervals and total break render on the expanded day',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Jun 11 auto-expands with a 40m and a 31m break.
    expect(find.textContaining('40m break'), findsOneWidget);
    expect(find.textContaining('31m break'), findsOneWidget);
    expect(find.text('Total break'), findsOneWidget);
    expect(find.text('1h 11m'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('more_vert opens the edit/delete action sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // .at(1) is a session row's ⋮ (the absent card's ⋮ is first).
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit action opens the edit attendance sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // .last is a session row's action (the absent card's ⋮ is first).
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Edit sheet shows the Sign in / Sign out sections + Submit.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete action shows a confirmation with what will be deleted',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // .last is a session row's action (the absent card's ⋮ is first).
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete attendance?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('absent day action offers Edit/Delete', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Absent card (Jun 12) is first; tap its ⋮ → Edit/Delete action sheet.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit on an absent day opens the date + note sheet',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit absent'), findsOneWidget);
    expect(find.text('Absent Date'), findsOneWidget);
    expect(find.text('Absent Note'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-admin (canEdit=false) shows no edit affordance',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness(canEdit: false));
    await tester.pumpAndSettle();

    // Jun 11 still auto-expands its sessions, but no ⋮ action is rendered.
    expect(find.text('Office'), findsWidgets);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the regular/overtime bar renders with a visible height',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final bar = find.byType(Av2SplitBar).first;
    expect(bar, findsOneWidget);
    // The bar itself must have real height...
    expect(tester.getSize(bar).height, greaterThan(0));
    // ...and its colored fills must too (guards the zero-height collapse bug).
    final fills = find.descendant(of: bar, matching: find.byType(ColoredBox));
    expect(tester.getSize(fills.first).height, greaterThan(0));
  });

  testWidgets('period chip opens the period sheet with both modes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jun 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Select period'), findsOneWidget);
    expect(find.text('Whole month'), findsOneWidget);
    expect(find.text('Custom range'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
