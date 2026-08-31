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
    // No 'Rejected' status exists — admins approve or leave pending; staff cancel.
    expect(find.text('Rejected'), findsNothing);
    expect(find.text('Cancelled'), findsOneWidget);
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

  testWidgets('admin inbox multi-selects then approves the selected set',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: RegAdminInboxScreen(requests: RegularizationFixtures.adminInbox),
    ));
    await tester.pumpAndSettle();

    // No action bar until something is selected.
    expect(find.textContaining('Approve selected'), findsNothing);

    // Select everything via the header toggle → the action bar appears.
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    final approveSelected = find.textContaining('Approve selected');
    expect(approveSelected, findsOneWidget);

    await tester.tap(approveSelected);
    await tester.pumpAndSettle();

    // Confirmation before approving the selected set.
    expect(find.textContaining('selected'), findsWidgets);
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

  testWidgets('admin-raised sheet promises auto-approval and names the staff',
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
                byAdmin: true,
                staffName: 'Mohan Sonone',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Admin copy: names the staff, promises an immediate apply, saves (not
    // "submits for approval").
    expect(find.text('Sign-out missing'), findsOneWidget);
    expect(find.textContaining('Mohan Sonone'), findsOneWidget);
    expect(find.textContaining('approved automatically'), findsOneWidget);
    expect(find.text('Save sign-out'), findsOneWidget);
    // Staff-only wording must not leak into admin mode.
    expect(find.text('Finish yesterday first'), findsNothing);
    expect(find.text('Confirm & submit'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
