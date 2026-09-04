import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_diff.dart';

/// Which occurrences of a recurring task an edit applies to — the choice the
/// user makes before a save is persisted (Events/Tasks PRD: a recurring edit
/// must never silently pick a scope on the user's behalf).
///
/// Each option maps onto a different Tasks API route, so the choice decides the
/// endpoint rather than just a flag on one request:
///
/// | Option              | Endpoint                                            |
/// |---------------------|-----------------------------------------------------|
/// | [thisOccurrence]    | `PATCH /tasks/assignments/{code}` (§5b)             |
/// | [thisAndFuture]     | `PATCH /tasks/{code}?scope=THIS_AND_FUTURE` (§3d)    |
/// | [entireSeries]      | `PATCH /tasks/{code}` (§3, server default `ALL`)     |
///
/// Ordered narrowest-first: the sheet lists them in this order and defaults to
/// the first, so an accidental Proceed changes as little as possible.
enum TaskEditScope {
  /// Only the card being edited — one assignee on one occurrence. Persisted
  /// through the per-assignment endpoint (§5b), which never touches the series,
  /// the shared occurrence, or any other assignee.
  thisOccurrence,

  /// Reanchors the series' schedule at this occurrence (§3d): everything before
  /// it stays exactly as scheduled under the old pattern, everything from it
  /// onward is regenerated under the new one. Requires an anchor occurrence
  /// code and at least one changed schedule field, or the API rejects it.
  thisAndFuture,

  /// The whole series (§3 with the default `scope=ALL`) — a schedule change
  /// regenerates every future occurrence from today.
  entireSeries;

  String get label {
    switch (this) {
      case TaskEditScope.thisOccurrence:
        return 'This occurrence only';
      case TaskEditScope.thisAndFuture:
        return 'This and future occurrences';
      case TaskEditScope.entireSeries:
        return 'Entire series';
    }
  }

  String get description {
    switch (this) {
      case TaskEditScope.thisOccurrence:
        return 'Changes apply to this date only';
      case TaskEditScope.thisAndFuture:
        return 'Splits the series at this date';
      case TaskEditScope.entireSeries:
        return 'Changes apply to all occurrences';
    }
  }

  /// The `?scope=` value for `PATCH /tasks/{code}`, or null for
  /// [thisOccurrence] — which goes to the assignment endpoint instead and so
  /// has no series scope at all.
  TaskUpdateScope? get seriesScope {
    switch (this) {
      case TaskEditScope.thisOccurrence:
        return null;
      case TaskEditScope.thisAndFuture:
        return TaskUpdateScope.thisAndFuture;
      case TaskEditScope.entireSeries:
        return TaskUpdateScope.all;
    }
  }

  /// True when the save lands on the series endpoint rather than the single
  /// assignment.
  bool get isSeriesWide => seriesScope != null;

  /// Only §3d takes an `anchorOccurrenceCode`, and it is mandatory there.
  bool get needsAnchorOccurrence => this == TaskEditScope.thisAndFuture;
}

/// Why one scope can't be used: [reason] is the short line rendered under the
/// option in the sheet, [saveMessage] the toast shown when a save is refused
/// because that scope was already chosen.
typedef TaskScopeUnavailable = ({String reason, String saveMessage});

/// Whether a save has to ask the user for a scope, and which options that ask
/// may offer. Pure so the rules are testable away from the form screen.
class TaskEditScopePrompt extends Equatable {
  const TaskEditScopePrompt({
    required this.isRequired,
    required this.unavailable,
  });

  /// Evaluates the rules when the user taps **Edit**, before anything has been
  /// changed. Only the rules that don't depend on the edit apply — the anchor
  /// occurrence's date can't change, but whether the schedule or repeat pattern
  /// moved isn't knowable yet.
  factory TaskEditScopePrompt.forOpen({
    required bool seriesIsRecurring,
    required DateTime occurrenceDate,
    required DateTime today,
  }) =>
      TaskEditScopePrompt._evaluate(
        seriesIsRecurring: seriesIsRecurring,
        diff: null,
        occurrenceDate: occurrenceDate,
        today: today,
      );

  /// Re-evaluates the rules against the edit the user actually made, so a scope
  /// chosen up front can be re-checked before it is sent.
  factory TaskEditScopePrompt.forSave({
    required bool seriesIsRecurring,
    required TaskEditDiff diff,
    required DateTime occurrenceDate,
    required DateTime today,
  }) =>
      TaskEditScopePrompt._evaluate(
        seriesIsRecurring: seriesIsRecurring,
        diff: diff,
        occurrenceDate: occurrenceDate,
        today: today,
      );

  /// [seriesIsRecurring] is the owning series' recurrence *as loaded* (§2a), not
  /// the value currently in the form: a one-off has exactly one occurrence, so
  /// there is nothing to disambiguate even if this edit turns it into a series.
  ///
  /// [occurrenceDate] is the edited card's own (pre-edit) occurrence date and
  /// [today] the school-local today. A null [diff] means the edit isn't known
  /// yet, so the rules that depend on it are skipped.
  ///
  /// A scope is ruled out only when the API genuinely cannot express the edit
  /// under it — never to steer the user. [TaskEditScope.entireSeries] is
  /// therefore always available, so there is always a way to save.
  factory TaskEditScopePrompt._evaluate({
    required bool seriesIsRecurring,
    required TaskEditDiff? diff,
    required DateTime occurrenceDate,
    required DateTime today,
  }) {
    final unavailable = <TaskEditScope, TaskScopeUnavailable>{};

    // The recurrence rule lives on the series; there is no per-occurrence form
    // of it, and quietly dropping the change would lose the user's edit.
    if (diff != null && diff.recurrenceChanged) {
      unavailable[TaskEditScope.thisOccurrence] = (
        reason: 'The repeat pattern applies to the whole series',
        saveMessage: 'The repeat pattern applies to the whole series, so it '
            "can't be changed for this occurrence only. Reopen Edit and choose "
            'a different option.',
      );
    }

    // §3d refuses an anchor occurrence that has already passed, and rejects a
    // reanchor with no schedule change to reanchor.
    final occurrenceHasPassed = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
    if (occurrenceHasPassed) {
      unavailable[TaskEditScope.thisAndFuture] = (
        reason: 'This occurrence has already passed',
        saveMessage: "This occurrence has already passed, so the series can't "
            'be split here.',
      );
    } else if (diff != null && !diff.scheduleChanged) {
      unavailable[TaskEditScope.thisAndFuture] = (
        reason: 'Change the schedule or repeat pattern to split the series here',
        saveMessage: 'To edit this and future occurrences, change the schedule '
            'or the repeat pattern first.',
      );
    }

    return TaskEditScopePrompt(
      isRequired: seriesIsRecurring,
      unavailable: Map.unmodifiable(unavailable),
    );
  }

  /// True when the user must be asked before the save is sent.
  final bool isRequired;

  /// Why each unavailable scope can't be used. A scope absent from this map is
  /// available.
  final Map<TaskEditScope, TaskScopeUnavailable> unavailable;

  bool canUse(TaskEditScope scope) => !unavailable.containsKey(scope);

  /// Short inline copy for the sheet's option list.
  String? reasonFor(TaskEditScope scope) => unavailable[scope]?.reason;

  /// Toast copy for a save refused because [scope] can't express this edit, or
  /// null when the scope is fine and the save may proceed.
  String? saveBlockedMessage(TaskEditScope scope) =>
      unavailable[scope]?.saveMessage;

  /// The sheet's view of the same thing: scope → short reason.
  Map<TaskEditScope, String> get unavailableReasons =>
      unavailable.map((scope, entry) => MapEntry(scope, entry.reason));

  /// The narrowest scope still on offer — what the sheet pre-selects, so an
  /// accidental Proceed changes as little as possible.
  TaskEditScope get defaultScope =>
      TaskEditScope.values.firstWhere(canUse, orElse: () {
        return TaskEditScope.entireSeries;
      });

  /// The scope to save under when [isRequired] is false — a one-off task only
  /// ever has this one occurrence to edit.
  TaskEditScope get scopeWhenNotAsked => TaskEditScope.thisOccurrence;

  @override
  List<Object?> get props => [isRequired, unavailable];
}
