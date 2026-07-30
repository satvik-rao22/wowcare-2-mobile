import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_badges.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_card.dart';

Task _task({
  TaskStatus status = TaskStatus.toDo,
  TaskPriority priority = TaskPriority.high,
}) =>
    Task(
      code: 'TSA_1',
      taskCode: 'TSK_1',
      title: 'Prepare fire drill',
      assigneeCode: 'STF_1',
      assigneeName: 'Alice Ng',
      status: status,
      priority: priority,
      startDate: DateTime.utc(2026, 8, 10),
      dueDate: DateTime.utc(2026, 8, 14),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    Task? task,
    VoidCallback? onStatusTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task ?? _task(),
            schoolTimeZone: 'America/New_York',
            onTap: () {},
            onStatusTap: onStatusTap,
          ),
        ),
      ),
    );
  }

  testWidgets('shows both the priority and the status', (tester) async {
    await pumpCard(tester);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('To Do'), findsOneWidget);
  });

  testWidgets('priority is read-only — it offers no way to be changed',
      (tester) async {
    // Inline priority editing was removed: it is set from the edit form only,
    // so the badge must not look or behave like a control.
    await pumpCard(tester, onStatusTap: () {});

    final priority = tester.widget<TaskPriorityBadge>(
      find.byType(TaskPriorityBadge),
    );
    expect(priority.priority, TaskPriority.high);
    // The dropdown caret is the badge's "I am editable" affordance; only the
    // status badge may show one.
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TaskPriorityBadge),
        matching: find.byIcon(Icons.expand_more),
      ),
      findsNothing,
    );
  });

  testWidgets('status stays editable and reports taps', (tester) async {
    var taps = 0;
    await pumpCard(tester, onStatusTap: () => taps++);

    expect(
      find.descendant(
        of: find.byType(TaskStatusBadge),
        matching: find.byIcon(Icons.expand_more),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(TaskStatusBadge));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a user who cannot manage the task gets no status affordance',
      (tester) async {
    await pumpCard(tester);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });
}
