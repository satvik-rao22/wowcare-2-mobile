import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_scope.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_edit_scope_sheet.dart';

void main() {
  /// Pumps a button that opens the sheet and hands back whatever it popped, so
  /// tests assert on the scope the caller actually receives.
  Future<TaskEditScope?> open(
    WidgetTester tester, {
    String taskTitle = 'Mobile task',
    Map<TaskEditScope, String> unavailableReasons = const {},
    required Future<void> Function(WidgetTester tester) interact,
  }) async {
    TaskEditScope? result;
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<TaskEditScope>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TaskEditScopeSheet(
                    taskTitle: taskTitle,
                    unavailableReasons: unavailableReasons,
                  ),
                );
                popped = true;
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
    await tester.pumpAndSettle();
    expect(popped, isTrue, reason: 'the sheet should have closed');
    return result;
  }

  Finder tile(TaskEditScope scope) =>
      find.byKey(ValueKey('task-edit-scope-${scope.name}'));

  bool isSelected(WidgetTester tester, TaskEditScope scope) =>
      tester
          .widgetList<Icon>(
            find.descendant(of: tile(scope), matching: find.byType(Icon)),
          )
          .any((icon) => icon.icon == Icons.radio_button_checked);

  testWidgets('names the task and asks which occurrences to modify',
      (tester) async {
    await open(
      tester,
      taskTitle: 'Mobile task',
      interact: (tester) async {
        expect(find.text('Modify "Mobile task"'), findsOneWidget);
        expect(
          find.text(
            'This is a recurring task. Which occurrences do you want to '
            'modify?',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
      },
    );
  });

  testWidgets('offers all three scopes with their descriptions',
      (tester) async {
    await open(
      tester,
      interact: (tester) async {
        for (final scope in TaskEditScope.values) {
          expect(tile(scope), findsOneWidget);
          expect(find.text(scope.label), findsOneWidget);
          expect(find.text(scope.description), findsOneWidget);
        }
        await tester.tap(find.text('Cancel'));
      },
    );
  });

  testWidgets('defaults to the narrowest scope', (tester) async {
    final result = await open(
      tester,
      interact: (tester) async {
        expect(isSelected(tester, TaskEditScope.thisOccurrence), isTrue);
        expect(isSelected(tester, TaskEditScope.thisAndFuture), isFalse);
        expect(isSelected(tester, TaskEditScope.entireSeries), isFalse);
        await tester.tap(find.text('Proceed'));
      },
    );
    expect(result, TaskEditScope.thisOccurrence);
  });

  testWidgets('Proceed returns the scope the user selected', (tester) async {
    final result = await open(
      tester,
      interact: (tester) async {
        await tester.tap(tile(TaskEditScope.entireSeries));
        await tester.pump();
        expect(isSelected(tester, TaskEditScope.entireSeries), isTrue);
        expect(isSelected(tester, TaskEditScope.thisOccurrence), isFalse);
        await tester.tap(find.text('Proceed'));
      },
    );
    expect(result, TaskEditScope.entireSeries);
  });

  testWidgets('the split scope is selectable when it is allowed',
      (tester) async {
    final result = await open(
      tester,
      interact: (tester) async {
        await tester.tap(tile(TaskEditScope.thisAndFuture));
        await tester.pump();
        await tester.tap(find.text('Proceed'));
      },
    );
    expect(result, TaskEditScope.thisAndFuture);
  });

  testWidgets('Cancel dismisses without choosing a scope', (tester) async {
    final result = await open(
      tester,
      interact: (tester) async {
        await tester.tap(tile(TaskEditScope.entireSeries));
        await tester.pump();
        await tester.tap(find.text('Cancel'));
      },
    );
    expect(result, isNull);
  });

  testWidgets('the close button dismisses without choosing a scope',
      (tester) async {
    final result = await open(
      tester,
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.close));
      },
    );
    expect(result, isNull);
  });

  testWidgets(
      'a disallowed split scope shows its reason and cannot be selected',
      (tester) async {
    // §3d rejects THIS_AND_FUTURE unless a schedule field actually changed, so
    // the option is spelled out as unavailable rather than left to 400.
    final result = await open(
      tester,
      unavailableReasons: const {
        TaskEditScope.thisAndFuture:
            'Change the schedule to split the series here',
      },
      interact: (tester) async {
        expect(
          find.text('Change the schedule to split the series here'),
          findsOneWidget,
        );
        await tester.tap(tile(TaskEditScope.thisAndFuture));
        await tester.pump();
        expect(isSelected(tester, TaskEditScope.thisAndFuture), isFalse);
        expect(isSelected(tester, TaskEditScope.thisOccurrence), isTrue);
        await tester.tap(find.text('Proceed'));
      },
    );
    expect(result, TaskEditScope.thisOccurrence);
  });

  testWidgets('pre-selects the narrowest scope that is actually available',
      (tester) async {
    // A repeat-pattern change can't apply to one date, so the default falls
    // through to the next offerable option rather than a disabled one.
    final result = await open(
      tester,
      unavailableReasons: const {
        TaskEditScope.thisOccurrence:
            'The repeat pattern applies to the whole series',
      },
      interact: (tester) async {
        expect(
          find.text('The repeat pattern applies to the whole series'),
          findsOneWidget,
        );
        expect(isSelected(tester, TaskEditScope.thisOccurrence), isFalse);
        expect(isSelected(tester, TaskEditScope.thisAndFuture), isTrue);
        await tester.tap(find.text('Proceed'));
      },
    );
    expect(result, TaskEditScope.thisAndFuture);
  });

  testWidgets('falls back to the entire series when nothing narrower is left',
      (tester) async {
    final result = await open(
      tester,
      unavailableReasons: const {
        TaskEditScope.thisOccurrence: 'Not available',
        TaskEditScope.thisAndFuture: 'Not available either',
      },
      interact: (tester) async {
        expect(isSelected(tester, TaskEditScope.entireSeries), isTrue);
        await tester.tap(find.text('Proceed'));
      },
    );
    expect(result, TaskEditScope.entireSeries);
  });
}
