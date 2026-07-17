import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_form_validation.dart';

void main() {
  const nineAm = TimeOfDay(hour: 9, minute: 0);
  const fivePm = TimeOfDay(hour: 17, minute: 0);
  final jul15 = DateTime(2026, 7, 15);
  final jul16 = DateTime(2026, 7, 16);

  group('isNonNegativeRange', () {
    test('rejects a due date before the start date', () {
      // Start 16th 00:00, due 15th 23:59 — the reported invalid case.
      expect(
        TaskFormValidation.isNonNegativeRange(
          startDate: jul16,
          startTime: const TimeOfDay(hour: 0, minute: 0),
          dueDate: jul15,
          dueTime: const TimeOfDay(hour: 23, minute: 59),
        ),
        isFalse,
      );
    });

    test('rejects same-day due time before start time', () {
      expect(
        TaskFormValidation.isNonNegativeRange(
          startDate: jul15,
          startTime: fivePm,
          dueDate: jul15,
          dueTime: nineAm,
        ),
        isFalse,
      );
    });

    test('accepts due after start', () {
      expect(
        TaskFormValidation.isNonNegativeRange(
          startDate: jul15,
          startTime: nineAm,
          dueDate: jul16,
          dueTime: fivePm,
        ),
        isTrue,
      );
    });

    test('accepts an identical (zero-length) range', () {
      expect(
        TaskFormValidation.isNonNegativeRange(
          startDate: jul15,
          startTime: nineAm,
          dueDate: jul15,
          dueTime: nineAm,
        ),
        isTrue,
      );
    });
  });

  group('canSubmit', () {
    bool submit({
      String title = 'Task',
      bool hasAssignee = true,
      bool recurring = false,
      TimeOfDay startTime = nineAm,
      TimeOfDay dueTime = fivePm,
      DateTime? startDate,
      DateTime? dueDate,
    }) =>
        TaskFormValidation.canSubmit(
          title: title,
          hasAssignee: hasAssignee,
          recurring: recurring,
          startDate: startDate ?? DateTime(2026, 7, 15),
          startTime: startTime,
          dueDate: dueDate ?? DateTime(2026, 7, 17),
          dueTime: dueTime,
        );

    test('blocks a blank title', () => expect(submit(title: '   '), isFalse));

    test('blocks when no assignee is chosen',
        () => expect(submit(hasAssignee: false), isFalse));

    test('one-off: blocks a negative window even with title + assignee', () {
      expect(
        submit(startDate: DateTime(2026, 7, 16), dueDate: DateTime(2026, 7, 15)),
        isFalse,
      );
    });

    test('one-off: allows a valid window', () => expect(submit(), isTrue));

    test('recurring: allowed regardless of the derived window', () {
      // A backwards start/due window must NOT block a recurring task, since
      // its dates are derived from the recurrence fields.
      expect(
        submit(
          recurring: true,
          startDate: DateTime(2026, 7, 16),
          dueDate: DateTime(2026, 7, 15),
        ),
        isTrue,
      );
    });

    test('recurring: still blocked without title/assignee', () {
      expect(submit(recurring: true, title: ''), isFalse);
      expect(submit(recurring: true, hasAssignee: false), isFalse);
    });
  });
}
