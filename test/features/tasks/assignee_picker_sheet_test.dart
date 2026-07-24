import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/tasks/widgets/assignee_picker_sheet.dart';

void main() {
  const options = <({String code, String name})>[
    (code: 'STF_1', name: 'Alice'),
    (code: 'STF_2', name: 'Bob'),
    (code: 'STF_3', name: 'Carol'),
  ];

  /// Pumps a button that opens the sheet and returns whatever it pops with, so
  /// tests can assert the exact `code -> name` selection handed back.
  Future<Map<String, String>?> openAndInteract(
    WidgetTester tester, {
    required Map<String, String> initialSelection,
    Set<String> lockedCodes = const {},
    required Future<void> Function(WidgetTester tester) interact,
  }) async {
    Map<String, String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<Map<String, String>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AssigneePickerSheet(
                    options: options,
                    initialSelection: initialSelection,
                    isLoading: false,
                    lockedCodes: lockedCodes,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await interact(tester);
    return result;
  }

  CheckboxListTile tileFor(WidgetTester tester, String name) =>
      tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, name),
      );

  testWidgets('locked assignees render checked, disabled, and labelled',
      (tester) async {
    await openAndInteract(
      tester,
      initialSelection: const {'STF_1': 'Alice'},
      lockedCodes: const {'STF_1'},
      interact: (tester) async {
        final locked = tileFor(tester, 'Alice');
        expect(locked.value, isTrue);
        // A null onChanged is what makes the tile non-interactive — the
        // existing assignee can't be unchecked.
        expect(locked.onChanged, isNull);
        expect(find.text('Already assigned'), findsOneWidget);

        final free = tileFor(tester, 'Bob');
        expect(free.value, isFalse);
        expect(free.onChanged, isNotNull);
      },
    );
  });

  testWidgets('tapping a locked tile leaves it selected', (tester) async {
    final result = await openAndInteract(
      tester,
      initialSelection: const {'STF_1': 'Alice'},
      lockedCodes: const {'STF_1'},
      interact: (tester) async {
        await tester.tap(find.text('Alice'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done (1)'));
        await tester.pumpAndSettle();
      },
    );

    // The locked assignee survives the interaction and comes back in the result.
    expect(result, {'STF_1': 'Alice'});
  });

  testWidgets('adding new assignees returns locked + newly-checked', (tester) async {
    final result = await openAndInteract(
      tester,
      initialSelection: const {'STF_1': 'Alice'},
      lockedCodes: const {'STF_1'},
      interact: (tester) async {
        await tester.tap(find.text('Bob'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Carol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done (3)'));
        await tester.pumpAndSettle();
      },
    );

    expect(result, {'STF_1': 'Alice', 'STF_2': 'Bob', 'STF_3': 'Carol'});
  });

  testWidgets('a freshly-added (non-locked) assignee can still be unchecked',
      (tester) async {
    final result = await openAndInteract(
      tester,
      initialSelection: const {},
      interact: (tester) async {
        await tester.tap(find.text('Bob')); // check
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bob')); // uncheck
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done (0)'));
        await tester.pumpAndSettle();
      },
    );

    expect(result, isEmpty);
  });

  testWidgets('search filters the staff list by name', (tester) async {
    await openAndInteract(
      tester,
      initialSelection: const {},
      interact: (tester) async {
        await tester.enterText(find.byType(TextField), 'car');
        await tester.pumpAndSettle();
        expect(find.text('Carol'), findsOneWidget);
        expect(find.text('Alice'), findsNothing);
        expect(find.text('Bob'), findsNothing);
      },
    );
  });
}
