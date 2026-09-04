import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_diff.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_scope.dart';

/// A recurring edit that changed only the flags passed in, so each case below
/// varies exactly the one thing it is about.
TaskEditDiff _diff({
  bool titleChanged = false,
  bool startTimeChanged = false,
  bool recurrenceChanged = false,
}) =>
    TaskEditDiff(
      titleChanged: titleChanged,
      descriptionChanged: false,
      assigneeChanged: false,
      priorityChanged: false,
      statusChanged: false,
      effortChanged: false,
      startDateChanged: false,
      startTimeChanged: startTimeChanged,
      dueDateChanged: false,
      dueTimeChanged: false,
      recurrenceChanged: recurrenceChanged,
      recurring: true,
      hasAddedAssignees: false,
    );

final _noChanges = _diff();
final _titleOnly = _diff(titleChanged: true);
final _rescheduled = _diff(startTimeChanged: true);
final _repeatChanged = _diff(recurrenceChanged: true);

void main() {
  test('every scope carries the sheet copy', () {
    expect(TaskEditScope.thisOccurrence.label, 'This occurrence only');
    expect(
      TaskEditScope.thisOccurrence.description,
      'Changes apply to this date only',
    );
    expect(TaskEditScope.thisAndFuture.label, 'This and future occurrences');
    expect(
      TaskEditScope.thisAndFuture.description,
      'Splits the series at this date',
    );
    expect(TaskEditScope.entireSeries.label, 'Entire series');
    expect(
      TaskEditScope.entireSeries.description,
      'Changes apply to all occurrences',
    );
  });

  test('the sheet offers the options in narrowest-first order', () {
    expect(TaskEditScope.values, [
      TaskEditScope.thisOccurrence,
      TaskEditScope.thisAndFuture,
      TaskEditScope.entireSeries,
    ]);
  });

  test('this-occurrence never touches the series endpoint', () {
    expect(TaskEditScope.thisOccurrence.seriesScope, isNull);
    expect(TaskEditScope.thisOccurrence.isSeriesWide, isFalse);
  });

  test('the series-wide scopes map onto the Tasks API §3 scope param', () {
    expect(
      TaskEditScope.thisAndFuture.seriesScope,
      TaskUpdateScope.thisAndFuture,
    );
    expect(TaskEditScope.thisAndFuture.isSeriesWide, isTrue);
    expect(TaskEditScope.entireSeries.seriesScope, TaskUpdateScope.all);
    expect(TaskEditScope.entireSeries.isSeriesWide, isTrue);
  });

  test('only this-and-future needs an anchor occurrence (§3d)', () {
    expect(TaskEditScope.thisAndFuture.needsAnchorOccurrence, isTrue);
    expect(TaskEditScope.entireSeries.needsAnchorOccurrence, isFalse);
    expect(TaskEditScope.thisOccurrence.needsAnchorOccurrence, isFalse);
  });

  group('TaskEditScopePrompt', () {
    final today = DateTime(2026, 7, 30);

    TaskEditScopePrompt prompt({
      bool seriesIsRecurring = true,
      TaskEditDiff? diff,
      DateTime? occurrenceDate,
    }) =>
        TaskEditScopePrompt.forSave(
          seriesIsRecurring: seriesIsRecurring,
          diff: diff ?? _rescheduled,
          occurrenceDate: occurrenceDate ?? DateTime(2026, 8, 3),
          today: today,
        );

    test('a one-off task is never asked which occurrences to modify', () {
      final result = prompt(seriesIsRecurring: false);
      expect(result.isRequired, isFalse);
      expect(result.scopeWhenNotAsked, TaskEditScope.thisOccurrence);
    });

    test('a recurring task always asks, even for a non-schedule edit', () {
      expect(prompt(diff: _titleOnly).isRequired, isTrue);
      expect(prompt(diff: _noChanges).isRequired, isTrue);
    });

    test('every scope is on offer for a future, rescheduled occurrence', () {
      final result = prompt();
      expect(result.unavailableReasons, isEmpty);
      for (final scope in TaskEditScope.values) {
        expect(result.canUse(scope), isTrue);
        expect(result.reasonFor(scope), isNull);
        expect(result.saveBlockedMessage(scope), isNull);
      }
      expect(result.defaultScope, TaskEditScope.thisOccurrence);
    });

    test('an available scope never blocks the save', () {
      // The toast is only ever raised for a scope the API cannot express.
      final result = prompt(diff: _titleOnly);
      expect(result.saveBlockedMessage(TaskEditScope.thisOccurrence), isNull);
      expect(result.saveBlockedMessage(TaskEditScope.entireSeries), isNull);
      expect(
        result.saveBlockedMessage(TaskEditScope.thisAndFuture),
        isNotNull,
      );
    });

    test('the entire-series scope can never be ruled out', () {
      // Whatever changed, there is always a way to save it: the whole series.
      expect(prompt(diff: _noChanges).canUse(TaskEditScope.entireSeries),
          isTrue);
      expect(
        prompt(
          diff: _repeatChanged,
          occurrenceDate: DateTime(2026, 7, 1),
        ).canUse(TaskEditScope.entireSeries),
        isTrue,
      );
    });

    group('this occurrence only', () {
      test('is ruled out by a repeat-pattern change', () {
        // The recurrence rule is a property of the series — there is no way to
        // apply it to one date, and dropping it silently would lose the edit.
        final result = prompt(diff: _repeatChanged);
        expect(result.canUse(TaskEditScope.thisOccurrence), isFalse);
        expect(result.reasonFor(TaskEditScope.thisOccurrence),
            contains('whole series'));
        expect(
          result.saveBlockedMessage(TaskEditScope.thisOccurrence),
          contains('whole series'),
        );
      });

      test('stays available for any non-recurrence edit', () {
        expect(prompt(diff: _titleOnly).canUse(TaskEditScope.thisOccurrence),
            isTrue);
        expect(prompt(diff: _rescheduled).canUse(TaskEditScope.thisOccurrence),
            isTrue);
      });
    });

    group('this and future occurrences', () {
      test('needs a schedule change to reanchor (§3d)', () {
        final result = prompt(diff: _titleOnly);
        expect(result.canUse(TaskEditScope.thisAndFuture), isFalse);
        expect(
          result.reasonFor(TaskEditScope.thisAndFuture),
          contains('schedule'),
        );
      });

      test('blocks the save with a toast naming what has to change', () {
        final result = prompt(diff: _titleOnly);
        final message =
            result.saveBlockedMessage(TaskEditScope.thisAndFuture)!;
        expect(message, contains('schedule'));
        expect(message, contains('repeat pattern'));
      });

      test('needs an anchor that is today or later (§3d)', () {
        final result = prompt(occurrenceDate: DateTime(2026, 7, 20));
        expect(result.canUse(TaskEditScope.thisAndFuture), isFalse);
        expect(
          result.reasonFor(TaskEditScope.thisAndFuture),
          contains('passed'),
        );
      });

      test('accepts today itself as an anchor', () {
        expect(
          prompt(occurrenceDate: today).canUse(TaskEditScope.thisAndFuture),
          isTrue,
        );
      });

      test('reports the past occurrence ahead of the missing schedule change',
          () {
        final result = prompt(
          diff: _titleOnly,
          occurrenceDate: DateTime(2026, 7, 20),
        );
        expect(
          result.reasonFor(TaskEditScope.thisAndFuture),
          contains('passed'),
        );
      });
    });

    group('forOpen (asked before the form is even filled in)', () {
      TaskEditScopePrompt opening({
        bool seriesIsRecurring = true,
        DateTime? occurrenceDate,
      }) =>
          TaskEditScopePrompt.forOpen(
            seriesIsRecurring: seriesIsRecurring,
            occurrenceDate: occurrenceDate ?? DateTime(2026, 8, 3),
            today: today,
          );

      test('only a recurring series is asked', () {
        expect(opening().isRequired, isTrue);
        expect(opening(seriesIsRecurring: false).isRequired, isFalse);
      });

      test('offers every scope, since nothing has been edited yet', () {
        // The schedule-change and repeat-pattern rules can't be evaluated
        // before the user has edited anything, so nothing is ruled out on them.
        final result = opening();
        expect(result.unavailableReasons, isEmpty);
        expect(result.defaultScope, TaskEditScope.thisOccurrence);
      });

      test('still rules out splitting on a past occurrence', () {
        // This one *is* knowable up front: the anchor date can't change.
        final result = opening(occurrenceDate: DateTime(2026, 7, 20));
        expect(result.canUse(TaskEditScope.thisAndFuture), isFalse);
        expect(
          result.reasonFor(TaskEditScope.thisAndFuture),
          contains('passed'),
        );
        expect(result.canUse(TaskEditScope.thisOccurrence), isTrue);
        expect(result.canUse(TaskEditScope.entireSeries), isTrue);
      });
    });

    test('the default scope skips over an unavailable option', () {
      // A repeat-pattern change rules out this-occurrence, so the narrowest
      // remaining scope is pre-selected instead.
      expect(prompt(diff: _repeatChanged).defaultScope,
          TaskEditScope.thisAndFuture);
      // Past anchor as well → only the whole series is left.
      expect(
        prompt(diff: _repeatChanged, occurrenceDate: DateTime(2026, 7, 1))
            .defaultScope,
        TaskEditScope.entireSeries,
      );
    });
  });
}
