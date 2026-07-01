import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/data/fixtures/regularization_fixtures.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/screens/reg_admin_inbox_screen.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/screens/reg_staff_list_screen.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_resolve_sheet.dart';

void main() {
  final sizes = <String, Size>{
    'mobile-small': const Size(320, 720),
    'mobile': const Size(390, 844),
    'tablet': const Size(768, 1024),
  };

  for (final entry in sizes.entries) {
    testWidgets('admin inbox renders without overflow at ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: RegAdminInboxScreen(requests: RegularizationFixtures.adminInbox),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mohan Sonone'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
    });
  }

  testWidgets('staff list shows needs-attention + requests', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: RegStaffListScreen(
        requests: RegularizationFixtures.myRequests,
        pendingGate: RegularizationFixtures.pendingGate,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Missed sign-out on'), findsWidgets);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin tile opens the decision sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: RegAdminInboxScreen(requests: RegularizationFixtures.adminInbox),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mohan Sonone'));
    await tester.pumpAndSettle();

    // Admin can only approve (with optional modify) — no reject.
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin inbox can bulk approve all', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: RegAdminInboxScreen(requests: RegularizationFixtures.adminInbox),
    ));
    await tester.pumpAndSettle();

    final approveAll = find.textContaining('Approve all');
    expect(approveAll, findsOneWidget);
    await tester.tap(approveAll);
    await tester.pumpAndSettle();

    // Confirmation dialog before approving everything.
    expect(find.textContaining('Approve all'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolve sheet merges context + correction in one sheet',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showRegResolveSheet(
                context,
                item: RegularizationFixtures.pendingGate,
                mandatory: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Finish yesterday first'), findsOneWidget);
    // Consequence + time + reason + submit all in one sheet.
    expect(find.textContaining("won't be counted"), findsOneWidget);
    expect(find.text('Actual sign-out time'), findsOneWidget);
    expect(find.text('Confirm & submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
