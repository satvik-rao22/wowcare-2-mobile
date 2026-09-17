import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_priority_meter.dart';

void main() {
  Future<void> pump(WidgetTester tester, TaskPriority priority) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskPriorityMeter(priority: priority)),
        ),
      );

  /// How many of the three level bars are filled.
  int filledBars(WidgetTester tester, TaskPriority priority) {
    final colour = TaskUiUtils.priorityColor(priority);
    return tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(const ValueKey('task-priority-bars')),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where((box) => (box.decoration as BoxDecoration).color == colour)
        .length;
  }

  group('TaskPriorityMeter', () {
    testWidgets('labels the field and its value', (tester) async {
      await pump(tester, TaskPriority.high);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('fills one bar per level, out of three', (tester) async {
      await pump(tester, TaskPriority.low);
      expect(filledBars(tester, TaskPriority.low), 1);

      await pump(tester, TaskPriority.medium);
      expect(filledBars(tester, TaskPriority.medium), 2);

      await pump(tester, TaskPriority.high);
      expect(filledBars(tester, TaskPriority.high), 3);
    });

    testWidgets('always renders three bars regardless of level',
        (tester) async {
      await pump(tester, TaskPriority.low);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('task-priority-bars')),
          matching: find.byType(DecoratedBox),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('is read-only — no tap target anywhere in it', (tester) async {
      // Priority is set from the edit form only, so the meter must expose no
      // gesture affordance at all.
      await pump(tester, TaskPriority.medium);
      expect(
        find.descendant(
          of: find.byType(TaskPriorityMeter),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(TaskPriorityMeter),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });
  });
}
