import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';

/// What an edit-form save actually changed, field group by field group.
///
/// Every Tasks API update endpoint treats a null/omitted field as "leave
/// unchanged", so the save path has to know precisely what moved. This is the
/// single source of that answer: the cubit builds the wire payload from it, and
/// the form asks it whether the `THIS_AND_FUTURE` scope is even offerable
/// (§3d rejects a reanchor with no schedule change).
class TaskEditDiff extends Equatable {
  const TaskEditDiff({
    required this.titleChanged,
    required this.descriptionChanged,
    required this.assigneeChanged,
    required this.priorityChanged,
    required this.statusChanged,
    required this.effortChanged,
    required this.startDateChanged,
    required this.startTimeChanged,
    required this.dueDateChanged,
    required this.dueTimeChanged,
    required this.recurrenceChanged,
    required this.recurring,
    required this.hasAddedAssignees,
  });

  /// Compares the edited [next] card against the loaded [previous] one.
  ///
  /// A null [previous] — the card isn't in the loaded board, e.g. a deep link or
  /// a board that has since been filtered — is treated as "everything changed",
  /// so an edit is never silently dropped for want of a baseline.
  ///
  /// [hasAddedAssignees] covers staff picked in the form who weren't already on
  /// the series: it isn't derivable from the two cards, since each card carries
  /// only its own assignee.
  factory TaskEditDiff.between({
    required Task? previous,
    required Task next,
    bool hasAddedAssignees = false,
  }) {
    if (previous == null) {
      return TaskEditDiff(
        titleChanged: true,
        descriptionChanged: true,
        assigneeChanged: true,
        priorityChanged: true,
        statusChanged: true,
        effortChanged: true,
        startDateChanged: true,
        startTimeChanged: true,
        dueDateChanged: true,
        dueTimeChanged: true,
        recurrenceChanged: true,
        recurring: next.recurring,
        hasAddedAssignees: true,
      );
    }
    return TaskEditDiff(
      titleChanged: previous.title != next.title,
      descriptionChanged: previous.description != next.description,
      assigneeChanged: previous.assigneeCode != next.assigneeCode,
      priorityChanged: previous.priority != next.priority,
      statusChanged: previous.status != next.status,
      effortChanged: previous.effort != next.effort,
      startDateChanged: previous.startDate != next.startDate,
      startTimeChanged: previous.startTime != next.startTime,
      dueDateChanged: previous.dueDate != next.dueDate,
      dueTimeChanged: previous.dueTime != next.dueTime,
      recurrenceChanged: previous.recurring != next.recurring ||
          previous.recurringPattern != next.recurringPattern ||
          previous.recurringEndDate != next.recurringEndDate ||
          previous.startDay != next.startDay,
      recurring: next.recurring,
      hasAddedAssignees: hasAddedAssignees,
    );
  }

  final bool titleChanged;
  final bool descriptionChanged;
  final bool assigneeChanged;
  final bool priorityChanged;
  final bool statusChanged;
  final bool effortChanged;

  final bool startDateChanged;
  final bool startTimeChanged;
  final bool dueDateChanged;
  final bool dueTimeChanged;

  /// Any of the recurrence definition changed (on/off, cadence, until date, or
  /// the weekly/monthly day).
  final bool recurrenceChanged;

  /// Whether the edited task is recurring — which decides *which* schedule
  /// fields actually reach the wire (see [scheduleChanged]).
  final bool recurring;

  /// Staff were picked who weren't already on the series roster.
  final bool hasAddedAssignees;

  /// The start date and/or start time-of-day moved.
  bool get startChanged => startDateChanged || startTimeChanged;

  /// The due date and/or due time-of-day moved.
  bool get dueChanged => dueDateChanged || dueTimeChanged;

  /// Whether the **series definition's** schedule moved — what makes the server
  /// cascade away and regenerate future occurrences, and the precondition §3d
  /// puts on a `THIS_AND_FUTURE` reanchor.
  ///
  /// A change to the recurrence definition itself always counts — including
  /// switching a series to a one-off or back.
  ///
  /// Beyond that, a recurring series' payload carries only `recurring`/`rrule`/
  /// `startTime`/`dueTime`: its start and due *dates* are derived from the rule
  /// and never sent. The form derives those dates from the recurrence too, so
  /// they drift from the edited card's own occurrence date on every single save
  /// — counting them here would regenerate the whole series for a title-only
  /// edit. A one-off, by contrast, does send concrete dates, so there they count.
  bool get scheduleChanged {
    if (recurrenceChanged) return true;
    if (recurring) return startTimeChanged || dueTimeChanged;
    return startChanged || dueChanged;
  }

  /// The roster must be resent (as a full replace) only when its membership
  /// actually moved: a reassignment or newly added assignees.
  bool get rosterChanged => assigneeChanged || hasAddedAssignees;

  /// Whether the user changed anything at all — including the start/due dates a
  /// recurring series never sends, since this answers "is this save a no-op?"
  /// rather than "what goes on the wire?".
  bool get hasChanges =>
      titleChanged ||
      descriptionChanged ||
      priorityChanged ||
      statusChanged ||
      effortChanged ||
      startChanged ||
      dueChanged ||
      recurrenceChanged ||
      rosterChanged;

  @override
  List<Object?> get props => [
        titleChanged,
        descriptionChanged,
        assigneeChanged,
        priorityChanged,
        statusChanged,
        effortChanged,
        startDateChanged,
        startTimeChanged,
        dueDateChanged,
        dueTimeChanged,
        recurrenceChanged,
        recurring,
        hasAddedAssignees,
      ];
}
