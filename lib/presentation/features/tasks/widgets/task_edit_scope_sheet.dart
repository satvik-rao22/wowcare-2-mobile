import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_scope.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_timezone.dart';

/// Asks how far an edit to a **recurring** task should reach before it is
/// persisted, mirroring the web app's "Modify …" dialog.
///
/// Pops with the chosen [TaskEditScope] when Proceed is tapped, or `null` when
/// dismissed (Cancel, the close button, or a swipe/back) — so the caller can
/// abandon the save entirely rather than guess a scope.
///
/// Scopes the current edit can't be expressed under are shown as unavailable
/// with the reason, rather than sent and left to fail: §3d rejects a reanchor
/// with no schedule change and refuses a past anchor occurrence, and a
/// recurrence-rule change has no per-occurrence form at all. See
/// [TaskEditScopePrompt], which decides them.
class TaskEditScopeSheet extends StatefulWidget {
  const TaskEditScopeSheet({
    required this.taskTitle,
    this.initial,
    this.unavailableReasons = const {},
    super.key,
  });

  /// Shown in the header so it's unambiguous which task is being modified.
  final String taskTitle;

  /// Pre-selected scope. Defaults to — and falls back to — the narrowest
  /// available option, so an accidental Proceed changes as little as possible.
  final TaskEditScope? initial;

  /// Why each unavailable scope can't be chosen; a scope absent from the map is
  /// selectable. The reason is rendered under that option.
  final Map<TaskEditScope, String> unavailableReasons;

  @override
  State<TaskEditScopeSheet> createState() => _TaskEditScopeSheetState();
}

class _TaskEditScopeSheetState extends State<TaskEditScopeSheet> {
  late TaskEditScope _selected = _initialSelection();

  TaskEditScope _initialSelection() {
    final initial = widget.initial;
    if (initial != null && _isEnabled(initial)) return initial;
    return TaskEditScope.values.firstWhere(
      _isEnabled,
      // Nothing narrower left: the whole series is always expressible.
      orElse: () => TaskEditScope.entireSeries,
    );
  }

  bool _isEnabled(TaskEditScope scope) =>
      !widget.unavailableReasons.containsKey(scope);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.sheetGrabber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _header(context),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'This is a recurring task. Which occurrences do you want to '
                'modify?',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
            for (final scope in TaskEditScope.values) _option(scope),
            const SizedBox(height: 6),
            _actions(context),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Modify "${widget.taskTitle}"',
              // A long task name must not push the options off the sheet.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, size: 20, color: AppPalette.iconMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _option(TaskEditScope scope) {
    final enabled = _isEnabled(scope);
    final selected = enabled && _selected == scope;
    final reason = widget.unavailableReasons[scope];
    return Padding(
      key: ValueKey('task-edit-scope-${scope.name}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _selected = scope) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.themeColor.withValues(alpha: 0.06)
                : AppPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.themeColor : AppPalette.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: !enabled
                    ? AppPalette.textMuted
                    : selected
                        ? AppColors.themeColor
                        : AppPalette.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? AppPalette.textPrimary
                            : AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scope.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: enabled
                            ? AppPalette.textSecondary
                            : AppPalette.textMuted,
                      ),
                    ),
                    if (reason != null && reason.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.errorColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 13.5)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: DecoratedBox(
              decoration: AppSurfaces.key(KeyVariant.primary, radius: 10),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Proceed',
                  style: TextStyle(
                    color: AppSurfaces.keyInk(KeyVariant.primary),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sentinel for "the user backed out of the scope sheet", distinct from "no
/// scope was needed" — [askTaskEditScope] returns a record so a dismissal can be
/// told apart from a one-off task that never needed asking.
typedef TaskEditScopeChoice = ({TaskEditScope? scope, bool cancelled});

/// Asks which occurrences an edit should apply to, on the way *into* the edit
/// form. Called from every Edit affordance (the list's card menu and the detail
/// screen), so the question is answered before the form even opens.
///
/// Only a recurring series is asked: a one-off has a single occurrence, so it
/// returns [TaskEditScope.thisOccurrence] with no sheet. [series] is the
/// already-fetched series when the caller has one (the detail screen does);
/// otherwise it's fetched here (§2a), since the flat assignment card carries no
/// recurrence flag of its own. A series that can't be fetched degrades to no
/// sheet and the narrow per-occurrence scope rather than blocking the edit.
///
/// The up-front question can't know what the user will change, so
/// [TaskEditScopePrompt.forOpen] only rules out what's already knowable; the
/// form re-checks the choice against the real edit before saving.
Future<TaskEditScopeChoice> askTaskEditScope({
  required BuildContext context,
  required TasksCubit cubit,
  required Task task,
  TaskSeries? series,
}) async {
  final seriesCode = task.taskCode.trim();
  var resolved = series;
  if (resolved == null && seriesCode.isNotEmpty) {
    resolved = await cubit.fetchSeriesDetail(seriesCode);
    if (!context.mounted) return (scope: null, cancelled: true);
  }
  if (resolved == null || !resolved.recurring) {
    return (scope: TaskEditScope.thisOccurrence, cancelled: false);
  }

  final schoolTimeZone = cubit.state.schoolTimeZone.trim().isEmpty
      ? TaskTimezone.lastKnownTimeZone
      : cubit.state.schoolTimeZone;
  // The card's occurrence date is a UTC wire date; "has it passed?" is a
  // school-calendar question, so compare both in school-local terms.
  final occurrence = TaskTimezone.fromUtcWire(
    utcDate: task.startDate,
    hhmm: task.startTime,
    ianaName: schoolTimeZone,
  );
  final prompt = TaskEditScopePrompt.forOpen(
    seriesIsRecurring: true,
    occurrenceDate: occurrence.$1,
    today: TaskTimezone.today(schoolTimeZone),
  );
  final title = task.title.trim();
  final chosen = await showTaskEditScopeSheet(
    context: context,
    taskTitle: title.isEmpty ? 'this task' : title,
    initial: prompt.defaultScope,
    unavailableReasons: prompt.unavailableReasons,
  );
  return (scope: chosen, cancelled: chosen == null);
}

/// Opens [TaskEditScopeSheet] as a modal bottom sheet. Returns the chosen scope,
/// or null when the user backs out — in which case the caller must not save.
Future<TaskEditScope?> showTaskEditScopeSheet({
  required BuildContext context,
  required String taskTitle,
  TaskEditScope? initial,
  Map<TaskEditScope, String> unavailableReasons = const {},
}) {
  return showModalBottomSheet<TaskEditScope>(
    context: context,
    backgroundColor: AppPalette.surfaceSunken,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => TaskEditScopeSheet(
      taskTitle: taskTitle,
      initial: initial,
      unavailableReasons: unavailableReasons,
    ),
  );
}
