import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_status_selector.dart';

void main() {
  Finder segment(TaskStatus status) =>
      find.byKey(ValueKey('task-status-segment-${status.name}'));

  Future<void> pump(
    WidgetTester tester, {
    TaskStatus status = TaskStatus.toDo,
    ValueChanged<TaskStatus>? onChanged,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskStatusSelector(status: status, onChanged: onChanged),
          ),
        ),
      );

  group('TaskStatusSelector', () {
    testWidgets('offers every status as its own segment', (tester) async {
      await pump(tester);
      for (final status in TaskStatus.values) {
        expect(segment(status), findsOneWidget);
        expect(find.text(status.label), findsOneWidget);
      }
    });

    testWidgets('marks the current status as selected', (tester) async {
      await pump(tester, status: TaskStatus.inProgress);

      final selector = tester.widget<TaskStatusSelector>(
        find.byType(TaskStatusSelector),
      );
      expect(selector.status, TaskStatus.inProgress);
      // Exactly one segment reads as chosen.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.descendant(
          of: segment(TaskStatus.inProgress),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('changing status is a single tap — no sheet in between',
        (tester) async {
      TaskStatus? picked;
      await pump(tester, onChanged: (status) => picked = status);

      await tester.tap(segment(TaskStatus.completed));
      await tester.pump();

      expect(picked, TaskStatus.completed);
    });

    testWidgets('re-tapping the current status is a no-op', (tester) async {
      var calls = 0;
      await pump(
        tester,
        status: TaskStatus.toDo,
        onChanged: (_) => calls++,
      );

      await tester.tap(segment(TaskStatus.toDo));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('is inert without an onChanged (no manage permission)',
        (tester) async {
      await pump(tester, status: TaskStatus.toDo);

      await tester.tap(segment(TaskStatus.completed));
      await tester.pump();

      // Still showing the original status — nothing to assert beyond the
      // absence of a crash and of any selection move.
      expect(
        find.descendant(
          of: segment(TaskStatus.toDo),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });
  });
}
