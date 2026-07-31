import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_diff.dart';

Task _card() => Task(
      code: 'TSA_1',
      taskCode: 'TSK_1',
      title: 'Water the plants',
      description: 'Front classroom',
      assigneeCode: 'STF_1',
      status: TaskStatus.toDo,
      priority: TaskPriority.medium,
      startDate: DateTime.utc(2026, 7, 15),
      startTime: '08:30',
      dueDate: DateTime.utc(2026, 7, 15),
      dueTime: '09:00',
      effort: 1.5,
      recurring: true,
      recurringPattern: TaskRecurrence.weekly,
      recurringEndDate: DateTime.utc(2026, 9, 30),
      startDay: 'MONDAY',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  test('an unchanged card reports no changes at all', () {
    final card = _card();
    final diff = TaskEditDiff.between(previous: card, next: card);
    expect(diff.hasChanges, isFalse);
    expect(diff.scheduleChanged, isFalse);
    expect(diff.rosterChanged, isFalse);
    expect(diff.titleChanged, isFalse);
    expect(diff.descriptionChanged, isFalse);
    expect(diff.assigneeChanged, isFalse);
    expect(diff.priorityChanged, isFalse);
    expect(diff.statusChanged, isFalse);
    expect(diff.effortChanged, isFalse);
  });

  test('a missing previous card treats every field as changed', () {
    // The card isn't in the loaded board (deep link / stale state): send
    // everything rather than silently dropping the user's edits.
    final diff = TaskEditDiff.between(previous: null, next: _card());
    expect(diff.hasChanges, isTrue);
    expect(diff.titleChanged, isTrue);
    expect(diff.descriptionChanged, isTrue);
    expect(diff.assigneeChanged, isTrue);
    expect(diff.priorityChanged, isTrue);
    expect(diff.statusChanged, isTrue);
    expect(diff.effortChanged, isTrue);
    expect(diff.startChanged, isTrue);
    expect(diff.dueChanged, isTrue);
    expect(diff.recurrenceChanged, isTrue);
    expect(diff.scheduleChanged, isTrue);
    expect(diff.rosterChanged, isTrue);
  });

  test('a title-only edit is not a schedule or roster change', () {
    final diff = TaskEditDiff.between(
      previous: _card(),
      next: _card().copyWith(title: 'Water the plants (north wing)'),
    );
    expect(diff.titleChanged, isTrue);
    expect(diff.scheduleChanged, isFalse);
    expect(diff.rosterChanged, isFalse);
    expect(diff.hasChanges, isTrue);
  });

  test('start date or start time moves count as a start change', () {
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card().copyWith(startDate: DateTime.utc(2026, 7, 16)),
      ).startChanged,
      isTrue,
    );
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card().copyWith(startTime: '10:00'),
      ).startChanged,
      isTrue,
    );
  });

  test('due date or due time moves count as a due change', () {
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card().copyWith(dueDate: DateTime.utc(2026, 7, 18)),
      ).dueChanged,
      isTrue,
    );
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card().copyWith(dueTime: '18:00'),
      ).dueChanged,
      isTrue,
    );
  });

  test('date and time moves are tracked separately', () {
    final movedDate = TaskEditDiff.between(
      previous: _card(),
      next: _card().copyWith(
        startDate: DateTime.utc(2026, 7, 16),
        dueDate: DateTime.utc(2026, 7, 16),
      ),
    );
    expect(movedDate.startDateChanged, isTrue);
    expect(movedDate.startTimeChanged, isFalse);
    expect(movedDate.dueDateChanged, isTrue);
    expect(movedDate.dueTimeChanged, isFalse);

    final movedTime = TaskEditDiff.between(
      previous: _card(),
      next: _card().copyWith(startTime: '10:00', dueTime: '11:00'),
    );
    expect(movedTime.startDateChanged, isFalse);
    expect(movedTime.startTimeChanged, isTrue);
    expect(movedTime.dueDateChanged, isFalse);
    expect(movedTime.dueTimeChanged, isTrue);
  });

  test('every recurrence field feeds recurrenceChanged', () {
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card().copyWith(recurring: false),
      ).recurrenceChanged,
      isTrue,
    );
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card()
            .copyWith(recurringPattern: () => TaskRecurrence.monthly),
      ).recurrenceChanged,
      isTrue,
    );
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card()
            .copyWith(recurringEndDate: () => DateTime.utc(2026, 12, 31)),
      ).recurrenceChanged,
      isTrue,
    );
    expect(
      TaskEditDiff.between(
        previous: _card(),
        next: _card().copyWith(startDay: () => 'FRIDAY'),
      ).recurrenceChanged,
      isTrue,
    );
  });

  group('scheduleChanged (what the series payload actually carries)', () {
    test('a recurring task counts times and the recurrence, never dates', () {
      // A recurring series sends only `recurring`/`rrule`/`startTime`/`dueTime`
      // — its start/due *dates* are derived from the rule and never sent, so a
      // shifted occurrence date must not be mistaken for a schedule change (it
      // would otherwise cascade away every future occurrence for, say, a
      // title-only edit).
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card().copyWith(
            startDate: DateTime.utc(2026, 8, 3),
            dueDate: DateTime.utc(2026, 8, 3),
          ),
        ).scheduleChanged,
        isFalse,
      );
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card().copyWith(startTime: '07:00'),
        ).scheduleChanged,
        isTrue,
      );
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card().copyWith(dueTime: '11:00'),
        ).scheduleChanged,
        isTrue,
      );
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card()
              .copyWith(recurringPattern: () => TaskRecurrence.monthly),
        ).scheduleChanged,
        isTrue,
      );
    });

    test('a one-off task counts its own dates and times', () {
      final oneOff = _card().copyWith(
        recurring: false,
        recurringPattern: () => null,
        recurringEndDate: () => null,
        startDay: () => null,
      );
      expect(
        TaskEditDiff.between(
          previous: oneOff,
          next: oneOff.copyWith(startDate: DateTime.utc(2026, 7, 16)),
        ).scheduleChanged,
        isTrue,
      );
      expect(
        TaskEditDiff.between(
          previous: oneOff,
          next: oneOff.copyWith(dueDate: DateTime.utc(2026, 7, 20)),
        ).scheduleChanged,
        isTrue,
      );
      expect(
        TaskEditDiff.between(
          previous: oneOff,
          next: oneOff.copyWith(dueTime: '18:00'),
        ).scheduleChanged,
        isTrue,
      );
    });

    test('turning recurrence on or off is always a schedule change', () {
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card().copyWith(recurring: false),
        ).scheduleChanged,
        isTrue,
      );
    });

    test('a non-schedule field never counts', () {
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card().copyWith(priority: TaskPriority.high),
        ).scheduleChanged,
        isFalse,
      );
      expect(
        TaskEditDiff.between(
          previous: _card(),
          next: _card().copyWith(title: 'Renamed'),
        ).scheduleChanged,
        isFalse,
      );
    });
  });

  test('a reassignment is both an assignee and a roster change', () {
    final diff = TaskEditDiff.between(
      previous: _card(),
      next: _card().copyWith(assigneeCode: 'STF_2'),
    );
    expect(diff.assigneeChanged, isTrue);
    expect(diff.rosterChanged, isTrue);
  });

  test('added assignees make it a roster change on their own', () {
    final diff = TaskEditDiff.between(
      previous: _card(),
      next: _card(),
      hasAddedAssignees: true,
    );
    expect(diff.assigneeChanged, isFalse);
    expect(diff.rosterChanged, isTrue);
    expect(diff.hasChanges, isTrue);
  });
}
