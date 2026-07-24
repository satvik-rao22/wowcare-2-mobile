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

  group('isEndOnOrAfterStart', () {
    test('accepts an end on or after the start', () {
      expect(
        TaskFormValidation.isEndOnOrAfterStart(start: jul15, until: jul16),
        isTrue,
      );
      expect(
        TaskFormValidation.isEndOnOrAfterStart(start: jul15, until: jul15),
        isTrue,
      );
    });

    test('rejects an end before the start', () {
      expect(
        TaskFormValidation.isEndOnOrAfterStart(start: jul16, until: jul15),
        isFalse,
      );
    });
  });

  group('isEffortValid', () {
    test('accepts blank (treated as 0)', () {
      expect(TaskFormValidation.isEffortValid('  '), isTrue);
    });
    test('accepts a non-negative decimal', () {
      expect(TaskFormValidation.isEffortValid('2.5'), isTrue);
      expect(TaskFormValidation.isEffortValid('0'), isTrue);
    });
    test('rejects a malformed or negative value', () {
      expect(TaskFormValidation.isEffortValid('1.2.3'), isFalse);
      expect(TaskFormValidation.isEffortValid('-1'), isFalse);
      expect(TaskFormValidation.isEffortValid('abc'), isFalse);
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
      DateTime? recurrenceEnd,
    }) =>
        TaskFormValidation.canSubmit(
          title: title,
          hasAssignee: hasAssignee,
          recurring: recurring,
          startDate: startDate ?? DateTime(2026, 7, 15),
          startTime: startTime,
          dueDate: dueDate ?? DateTime(2026, 7, 17),
          dueTime: dueTime,
          recurrenceEnd: recurrenceEnd,
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

    test('recurring: blocks a negative derived window', () {
      // The caller resolves the recurrence to concrete dates; a same-day
      // derivation whose due time precedes the start time is invalid.
      expect(
        submit(
          recurring: true,
          startDate: jul15,
          dueDate: jul15,
          startTime: fivePm,
          dueTime: nineAm,
          recurrenceEnd: jul16,
        ),
        isFalse,
      );
    });

    test('recurring: allows a valid derived window with an end date', () {
      expect(
        submit(
          recurring: true,
          startDate: jul15,
          dueDate: jul16,
          recurrenceEnd: jul16,
        ),
        isTrue,
      );
    });

    test('recurring: blocks a missing "Until" end date', () {
      expect(submit(recurring: true, recurrenceEnd: null), isFalse);
    });

    test('recurring: blocks an end date before the start', () {
      expect(
        submit(
          recurring: true,
          startDate: jul16,
          dueDate: jul16,
          recurrenceEnd: jul15,
        ),
        isFalse,
      );
    });

    test('recurring: still blocked without title/assignee', () {
      expect(submit(recurring: true, title: ''), isFalse);
      expect(submit(recurring: true, hasAssignee: false), isFalse);
    });
  });
}
