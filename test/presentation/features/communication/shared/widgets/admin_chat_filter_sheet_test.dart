/// Widget tests for [AdminChatFilterSheet] after its Mandate 2 conversion from
/// `setState` to `ValueNotifier`s. These assert BEHAVIOUR (selection → Apply
/// payload, Clear reset), so they prove the conversion preserved functionality
/// rather than testing the notifier mechanics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/admin_chat_filter_sheet.dart';

void main() {
  // Captures from the last Apply/Clear so each test can assert what the sheet
  // handed back.
  late Set<String> appliedClassrooms;
  late Set<String> appliedTags;
  late String? appliedStatus;
  late bool cleared;

  Future<void> openSheet(
    WidgetTester tester, {
    Set<String> selectedClassrooms = const {},
    Set<String> selectedTags = const {},
    String? selectedStatus,
  }) async {
    appliedClassrooms = {};
    appliedTags = {};
    appliedStatus = 'UNSET';
    cleared = false;

    // The sheet (three sections + action row) is taller than the default
    // 800x600 test viewport, which would push Apply/Clear below the fold and
    // out of hit-testing range. Give it a tall surface for the duration.
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => AdminChatFilterSheet(
                  classroomOptions: const ['Sunflower', 'Rose', 'Tulip'],
                  tagOptions: const ['Allergy', 'VIP'],
                  statusOptions: const ['active', 'upcoming', 'inactive'],
                  selectedClassrooms: selectedClassrooms,
                  selectedTags: selectedTags,
                  selectedStatus: selectedStatus,
                  onApply: (c, t, s) {
                    appliedClassrooms = c;
                    appliedTags = t;
                    appliedStatus = s;
                  },
                  onClear: () => cleared = true,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a tapped classroom chip is carried out on Apply', (tester) async {
    await openSheet(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Sunflower'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Tulip'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(appliedClassrooms, {'Sunflower', 'Tulip'});
    expect(appliedTags, isEmpty);
  });

  testWidgets('tapping a selected chip again removes it', (tester) async {
    await openSheet(tester, selectedClassrooms: {'Rose'});

    await tester.tap(find.widgetWithText(FilterChip, 'Rose'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(appliedClassrooms, isEmpty);
  });

  testWidgets('status is single-select — a second pick replaces the first', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Upcoming'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(appliedStatus, 'upcoming');
  });

  testWidgets('Clear fires onClear and does not call onApply', (tester) async {
    await openSheet(tester, selectedTags: {'VIP'});

    await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
    // onApply left its sentinel untouched.
    expect(appliedStatus, 'UNSET');
  });
}
