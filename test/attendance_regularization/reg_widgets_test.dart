import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/data/fixtures/regularization_fixtures.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/screens/reg_admin_inbox_screen.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/screens/reg_staff_list_screen.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_gate_dialog.dart';

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

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gate dialog shows confirm + correct actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showRegGateDialog(
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
    // Confirm button carries the soft sign-out time (17:30 → 05:30p).
    expect(find.text('I left at 05:30p'), findsOneWidget);
    expect(find.text('I left at a different time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
