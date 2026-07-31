import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_schedule_utils.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_timezone.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/view/task_form_screen.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_attachment_thumbnail.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_badges.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_priority_meter.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_status_selector.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_edit_scope_sheet.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Read-only task view with edit/delete affordances for users who own the
/// task (PRD FR-TK-26/28).
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({required this.taskCode, super.key});

  static const String routeName = '/dashboard/tasks/detail';

  final String taskCode;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  /// The owning series, refetched on open and after every edit. The flat
  /// assignment card carries neither the start time-of-day nor the recurrence
  /// rule (both live only on the series, bridged by `taskCode`), so we fetch
  /// §2a detail to fill the Schedule section's "Starts" time and "Repeats"
  /// row. Null until it loads / on failure — the UI degrades to the card's
  /// own (date-level) data.
  TaskSeries? _series;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshSeries());
    unawaited(_loadAttachments());
  }

  /// Pulls this task's attachments into the shared cache. The card list may
  /// already have loaded them, in which case this is a no-op.
  Future<void> _loadAttachments() async {
    final cubit = context.read<TasksCubit>();
    final seriesCode = _seriesCodeFrom(cubit.state);
    if (seriesCode.isEmpty) return;
    await cubit.ensureAttachmentsLoaded(seriesCode);
  }

  String _seriesCodeFrom(TasksState state) =>
      state.taskByCode(widget.taskCode)?.taskCode.trim() ?? '';

  /// (Re)fetches the owning series and applies it if still mounted. Called on
  /// open and again after an edit, since a recurring task's start time only
  /// ever changes on the series — the once-fetched [_series] would otherwise
  /// keep showing the pre-edit time forever after a save.
  Future<void> _refreshSeries() async {
    final seriesCode = _seriesCodeFrom(context.read<TasksCubit>().state);
    if (seriesCode.isEmpty) return;
    final series = await context.read<TasksCubit>().fetchSeriesDetail(seriesCode);
    if (mounted && series != null) setState(() => _series = series);
  }

  @override
  Widget build(BuildContext context) {
    final taskCode = widget.taskCode;
    final roles = context.watch<RoleCubit>();
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      // Both fetches need the card's series code, which a deep link or a cold
      // cubit doesn't have yet at initState — so run them again the moment the
      // card (and with it the series code) actually arrives, instead of leaving
      // the schedule and attachments permanently unloaded.
      body: BlocListener<TasksCubit, TasksState>(
        listenWhen: (previous, current) =>
            _seriesCodeFrom(previous).isEmpty &&
            _seriesCodeFrom(current).isNotEmpty,
        listener: (context, state) {
          unawaited(_refreshSeries());
          unawaited(_loadAttachments());
        },
        child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final task = state.taskByCode(taskCode);
          if (task == null) {
            return const Center(
              child: Text(
                'Task not found',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          // Read gate (PRD §5.2): a staff member may only open their own tasks,
          // parents none at all — so a deep link or a stale push can't surface
          // someone else's task even though the card came from the shared cubit.
          if (!TaskAccess.canViewTask(
            roles: roles,
            task: task,
            userCode: state.currentUserCode,
            staffCode: state.currentStaffCode,
          )) {
            return _noAccess();
          }
          final canManage = TaskAccess.canManageTask(
            roles: roles,
            task: task,
            userCode: state.currentUserCode,
            staffCode: state.currentStaffCode,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerRow(context, task, canManage),
                if (task.isOverdue) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: TaskOverdueBadge(),
                  ),
                ],
                const SizedBox(height: 12),
                _statusCard(context, task, canManage),
                const SizedBox(height: 10),
                TaskPriorityMeter(priority: task.priority),
                const SizedBox(height: 12),
                _assigneeCard(task),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _sectionCard(
                    title: 'Description',
                    child: Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _scheduleCard(task, state.schoolTimeZone),
                if (state.attachmentsFor(task).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _attachmentCard(
                    context,
                    task,
                    state.attachmentsFor(task),
                    canManage: canManage,
                  ),
                ] else if (!state.attachmentsAreReadable(task.taskCode)) ...[
                  // Say so rather than rendering nothing: "this task has no
                  // attachments" and "we couldn't read them" look identical
                  // otherwise, which is exactly how an attached file appears to
                  // vanish.
                  const SizedBox(height: 10),
                  _attachmentsUnavailableCard(),
                ],
                const SizedBox(height: 14),
                _footer(task),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _attachmentsUnavailableCard() {
    return _sectionCard(
      title: 'Attachments',
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "This task's attachments couldn't be loaded. Pull to refresh or "
              'try again in a moment.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown instead of the task when the persona has no read access to it
  /// (PRD §5.2). Deliberately reveals nothing about the task itself.
  Widget _noAccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 44, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'You do not have access to this task.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(BuildContext context, Task task, bool canManage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            task.title,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (canManage) ...[
          IconButton(
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.themeColor, size: 22),
            onPressed: () async {
              // A recurring task asks which occurrences to modify before the
              // form opens; [_series] is already loaded here, so no refetch.
              final choice = await askTaskEditScope(
                context: context,
                cubit: context.read<TasksCubit>(),
                task: task,
                series: _series,
              );
              if (choice.cancelled || !mounted) return;
              await context.push(
                TaskFormScreen.routeName,
                extra: <String, dynamic>{
                  'taskCode': task.code,
                  'editScope': choice.scope,
                },
              );
              // The edit may have changed the series' start time/recurrence —
              // the cached [_series] would otherwise keep showing the old one.
              if (mounted) unawaited(_refreshSeries());
            },
          ),
          IconButton(
            tooltip: 'Delete task',
            icon: const Icon(Icons.delete_outline,
                color: AppColors.errorColor, size: 22),
            onPressed: () => _confirmDelete(context, task),
          ),
        ],
      ],
    );
  }

  /// Status is the task's primary action, so it gets the loudest element on the
  /// screen: a full-width segmented control that both reports the current state
  /// and moves it in one tap (PRD FR-TK-16). Priority sits just below it as a
  /// read-only meter — same ownership rule as the list, but no inline edit.
  Widget _statusCard(BuildContext context, Task task, bool canManage) {
    return _sectionCard(
      title: 'Status',
      child: TaskStatusSelector(
        status: task.status,
        onChanged: canManage
            ? (status) => context.read<TasksCubit>().changeStatus(
                  task.code,
                  status,
                )
            : null,
      ),
    );
  }

  Widget _assigneeCard(Task task) {
    return _sectionCard(
      title: 'Assignee',
      child: Row(
        children: [
          TaskAssigneeAvatar(
            name: task.assigneeName,
            code: task.assigneeCode,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.assigneeName.isEmpty ? 'Unassigned' : task.assigneeName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(Task baseTask, String schoolTimeZone) {
    // The flat card has no start time-of-day and no recurrence; fold in the
    // series (when loaded) so "Starts" shows the real time and "Repeats" the
    // real cadence. Due date/time stay from the card — they're per-occurrence.
    final task = _withSeriesSchedule(baseTask);
    final effort = TaskUiUtils.effortLabel(task.effort);
    // The wire's start/due date+time are UTC; convert together (the date can
    // itself shift a day depending on the school's offset) before display.
    final start = TaskTimezone.fromUtcWire(
      utcDate: task.startDate,
      hhmm: task.startTime,
      ianaName: schoolTimeZone,
    );
    final due = TaskTimezone.fromUtcWire(
      utcDate: task.dueDate,
      hhmm: task.dueTime,
      ianaName: schoolTimeZone,
    );
    return _sectionCard(
      title: 'Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(
            Icons.play_circle_outline,
            'Starts',
            '${DateFormat('EEE, MMM d, yyyy').format(start.$1)}'
                ' • ${TaskUiUtils.formatTimeOfDay(start.$2)}',
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.flag_outlined,
            'Due',
            '${DateFormat('EEE, MMM d, yyyy').format(due.$1)}'
                ' • ${TaskUiUtils.formatTimeOfDay(due.$2)}',
            valueColor: task.isOverdue ? TaskUiUtils.overdueColor : null,
          ),
          if (task.recurring) ...[
            const SizedBox(height: 8),
            _detailRow(
              Icons.repeat,
              'Repeats',
              TaskUiUtils.recurrenceLabel(task) +
                  (task.recurringEndDate != null
                      ? ' • until ${DateFormat('MMM d, yyyy').format(task.recurringEndDate!)}'
                      : ''),
            ),
          ],
          if (effort.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(Icons.timer_outlined, 'Estimated effort', effort),
          ],
        ],
      ),
    );
  }

  /// Overlays the series' schedule (start time + recurrence) onto the flat
  /// assignment card. Returns [task] unchanged until the series loads, so the
  /// screen renders immediately and fills in the time/recurrence once fetched.
  Task _withSeriesSchedule(Task task) {
    final series = _series;
    if (series == null) return task;
    return TaskScheduleUtils.withSeriesSchedule(task, series);
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attachmentCard(
    BuildContext context,
    Task task,
    List<TaskAttachment> attachments, {
    required bool canManage,
  }) {
    final service = context.read<TasksCubit>().imageUploadService;
    return _sectionCard(
      title: attachments.length == 1
          ? 'Attachment'
          : 'Attachments (${attachments.length})',
      child: Column(
        children: [
          for (var i = 0; i < attachments.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            _attachmentRow(
              context,
              task,
              attachments[i],
              service,
              // Only an attachment the list endpoint gave a row code for can
              // be detached; one without it must be removed via the form's
              // assetCodes replace instead.
              canRemove: canManage && attachments[i].code.isNotEmpty,
            ),
          ],
        ],
      ),
    );
  }

  /// One attachment row: preview thumbnail, name + size, and a chevron. Tapping
  /// anywhere on it previews images/video in-app or hands documents to the OS.
  Widget _attachmentRow(
    BuildContext context,
    Task task,
    TaskAttachment attachment,
    ImageUploadService service, {
    required bool canRemove,
  }) {
    final subtitle = <String>[
      TaskAttachmentUtils.extensionLabel(attachment.fileName),
      if (attachment.displaySize.isNotEmpty) attachment.displaySize,
      if (!attachment.isReady) 'processing…',
    ].join(' • ');

    return InkWell(
      onTap: () => TaskAttachmentUtils.open(
        context: context,
        attachment: attachment,
        service: service,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            TaskAttachmentThumbnail(
              attachment: attachment,
              uploadService: service,
              size: 44,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName.isEmpty
                        ? 'Attachment'
                        : attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              attachment.isDocument
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: Colors.grey[500],
            ),
            if (canRemove)
              IconButton(
                tooltip: 'Remove attachment',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                onPressed: () => _confirmDetach(context, task, attachment),
              ),
          ],
        ),
      ),
    );
  }

  /// Detaching is destructive and immediate (unlike the form, which stages
  /// changes until save), so it asks first.
  Future<void> _confirmDetach(
    BuildContext context,
    Task task,
    TaskAttachment attachment,
  ) async {
    final cubit = context.read<TasksCubit>();
    final name = attachment.fileName.isEmpty
        ? 'this attachment'
        : '"${attachment.fileName}"';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove attachment?'),
        content: Text('Do you want to remove $name from this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await cubit.detachAttachment(
      taskCode: task.taskCode,
      attachmentCode: attachment.code,
    );
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: ok ? 'Attachment removed' : 'Could not remove the attachment.',
      isSuccess: ok,
      isError: !ok,
    );
  }

  Widget _footer(Task task) {
    return Text(
      'Created by ${task.createdByName.isEmpty ? 'Unknown' : task.createdByName}'
      ' • ${DateFormat('MMM d, yyyy').format(task.createdAt)}',
      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Do you want to delete this task - "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await cubit.delete(task.code);
      if (ok && context.mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Task deleted',
          isSuccess: true,
        );
        context.pop();
      }
    }
  }
}
