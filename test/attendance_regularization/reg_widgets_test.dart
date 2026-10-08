import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_regularization/data/fixtures/regularization_fixtures.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/regularization_request.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/entry/reg_requests_list.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_field_label.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_request_detail_sheet.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_request_tile.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/screens/reg_admin_inbox_view.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_bulk_signin_gate_sheet.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/widgets/reg_resolve_sheet.dart';

void main() {
  final sizes = <String, Size>{
    'mobile-small': const Size(320, 720),
    'mobile': const Size(390, 844),
    'tablet': const Size(768, 1024),
  };

  for (final entry in sizes.entries) {
    testWidgets('admin inbox renders without overflow at ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegAdminInboxView(
              requests: RegularizationFixtures.adminInbox,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mohan Sonone'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
    });
  }

  testWidgets('the raiser gets edit, and nothing else', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegRequestsList(
              requests: RegularizationFixtures.myRequests,
              currentUserCode: 'STF_1',
              onSelectChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsNWidgets(2));
    // Not an admin, so no checkbox and no bulk bar however the callbacks are
    // wired — the list decides from the viewer, not from what it is handed.
    expect(find.byType(Checkbox), findsNothing);
    expect(find.textContaining('Approve selected'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    // `status` has exactly two values (§6). Neither of the removed states may
    // reappear: there is no reject, and cancel was replaced by edit (§8.4).
    expect(find.text('Rejected'), findsNothing);
    expect(find.text('Cancelled'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an admin gets a checkbox on pending rows only', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = RegularizationFixtures.myRequests;
    final pending = requests.where((r) => r.status.isPending).length;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegRequestsList(
              requests: requests,
              currentUserCode: 'USR_ADMIN',
              isAdmin: true,
              onSelectChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNWidgets(pending));
    // An admin is not the raiser, so review replaces edit.
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('$pending pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin inbox lays out inside a TabBarView', (tester) async {
    // Its only home is the Staff Attendance "Request" tab, so the Column +
    // Expanded it returns has to survive a tab's box constraints.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Daily'),
                  Tab(text: 'Request'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                const SizedBox.shrink(),
                RegAdminInboxView(requests: RegularizationFixtures.adminInbox),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Request'));
    await tester.pumpAndSettle();

    expect(find.text('Mohan Sonone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RegFieldLabel', () {
    testWidgets('a required field gets a red asterisk, not a word', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RegFieldLabel('Reason', isRequired: true)),
        ),
      );

      final span = tester.widget<Text>(find.byType(Text)).textSpan!;
      expect(span.toPlainText(), 'Reason *');
      // The marker must be the app's red, or it reads as part of the label.
      final marker = (span as TextSpan).children!.last as TextSpan;
      expect(marker.text, ' *');
      expect(marker.style?.color, Av2Colors.danger);
    });

    testWidgets('an optional field carries no marker', (tester) async {
      // No `*` means optional. A pre-filled field that cannot be blank gets
      // none either, so the marker never promises an empty state.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RegFieldLabel('Sign-out time'))),
      );

      expect(
        tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText(),
        'Sign-out time',
      );
    });
  });

  group('request detail sheet', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      RegularizationRequest r,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showRegRequestDetailSheet(context, request: r),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('an approved request shows the approver note and both times', (
      tester,
    ) async {
      // The bug this sheet exists for: an admin who adjusted a time and wrote
      // why could never read that note back anywhere.
      final approved = RegularizationFixtures.myRequests.firstWhere(
        (r) => r.status.isApproved && r.wasModified,
      );

      await pumpDetail(tester, approved);

      expect(find.text(approved.approvalNote!), findsOneWidget);
      expect(find.textContaining('Chaitanya Bhave'), findsOneWidget);
      // Both times, so the adjustment is visible rather than silently applied.
      expect(find.textContaining('adjusted from'), findsOneWidget);
      expect(find.text(approved.reason), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pending request shows no approval section', (tester) async {
      final pending = RegularizationFixtures.myRequests.firstWhere(
        (r) => r.status.isPending,
      );

      await pumpDetail(tester, pending);

      expect(find.text('Approved by'), findsNothing);
      expect(find.text('Reason for change'), findsNothing);
      expect(find.text(pending.reason), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('every row in the profile list is tappable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = RegularizationFixtures.myRequests;
    final tapped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegRequestsList(
              requests: requests,
              // Not the raiser and not an admin: every row is read-only, and
              // read-only used to mean dead.
              currentUserCode: 'USR_SOMEONE_ELSE',
              onShowDetail: (r) => tapped.add(r.code),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(requests.length));
    for (final r in requests) {
      await tester.tap(find.byType(RegRequestTile).at(requests.indexOf(r)));
      await tester.pumpAndSettle();
    }
    expect(tapped, requests.map((r) => r.code).toList());
  });

  testWidgets('admin tile opens the decision sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegAdminInboxView(requests: RegularizationFixtures.adminInbox),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mohan Sonone'));
    await tester.pumpAndSettle();

    // Admin can only approve (with optional modify) — no reject.
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin inbox multi-selects then approves the selected set', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegAdminInboxView(requests: RegularizationFixtures.adminInbox),
        ),
      ),
    );
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

  testWidgets('resolve sheet merges context + correction in one sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Finish yesterday first'), findsOneWidget);
    // Consequence + time + reason + submit all in one sheet.
    expect(find.textContaining("won't be counted"), findsOneWidget);
    expect(find.text('Actual sign-out time'), findsOneWidget);
    // §8.2 — no "confirm" shortcut: a reason is required whether or not the
    // pre-filled time was changed. Marked the way every other form in the
    // app marks one: a red `*`, not the word "(required)".
    expect(find.text('Reason *'), findsOneWidget);
    expect(find.textContaining('(required)'), findsNothing);
    expect(find.textContaining('(optional)'), findsNothing);
    expect(find.text('Confirm & submit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolve sheet blocks submit until a reason is given', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    RegResolveResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => result = await showRegResolveSheet(
                  context,
                  item: RegularizationFixtures.pendingGate,
                  mandatory: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Submitting with a blank reason is refused, and the sheet stays open.
    await tester.tap(find.text('Confirm & submit'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Add a reason.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'parent meeting');
    await tester.tap(find.text('Confirm & submit'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.reason, 'parent meeting');
    // Defaults to the suggested school end time (17:30).
    expect(result!.signOutLocal.hour, 17);
    expect(result!.signOutLocal.minute, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin-raised sheet promises auto-approval and names the staff', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
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

  group('bulk sign-in gate', () {
    Widget harness(void Function(List<RegBulkGateItem>?) onResult) =>
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => onResult(
                    await showRegBulkSignInGateSheet(
                      context,
                      blocked: RegularizationFixtures.bulkSignInGate,
                      otherCount: 40,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

    testWidgets('lists the blocked staff and closes all in one tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      List<RegBulkGateItem>? result;
      await tester.pumpWidget(harness((r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Header names the blocked count and reassures about the rest.
      expect(find.text('10 staff need yesterday closed'), findsOneWidget);
      expect(find.text('40 others will sign in normally'), findsOneWidget);
      // Staff are listed by name (sorted), each with its own row.
      expect(find.text('Aisha Rahman'), findsOneWidget);
      // §8.2 — the shared reason is required even when no row was corrected.
      expect(find.text('Reason *'), findsOneWidget);
      expect(find.textContaining('(required)'), findsNothing);
      expect(find.textContaining('(optional)'), findsNothing);

      // So submitting without one is refused.
      await tester.tap(find.text('Close all 10 & sign them in'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('Add a reason.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'forgot to sign out',
      );
      await tester.tap(find.text('Close all 10 & sign them in'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.length, 10);
      expect(result!.every((i) => i.reason == 'forgot to sign out'), isTrue);
      // Defaults to the suggested school end time (17:30).
      expect(result!.first.signOutLocal.hour, 17);
      expect(result!.first.signOutLocal.minute, 30);
      expect(tester.takeException(), isNull);
    });

    testWidgets('skip returns nothing so the other staff still sign in', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      List<RegBulkGateItem>? result;
      var called = false;
      await tester.pumpWidget(
        harness((r) {
          result = r;
          called = true;
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip — sign in the other 40'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
