import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/view/task_form_screen.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_badges.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Read-only task view with edit/delete affordances for users who own the
/// task (PRD FR-TK-26/28).
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({required this.taskCode, super.key});

  static const String routeName = '/dashboard/tasks/detail';

  final String taskCode;

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: BlocBuilder<TasksCubit, TasksState>(
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (task.isOverdue) const TaskOverdueBadge(),
                    TaskPriorityBadge(priority: task.priority),
                    TaskStatusBadge(status: task.status),
                  ],
                ),
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
                _scheduleCard(task),
                if (task.attachmentName != null &&
                    task.attachmentName!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _attachmentCard(context, task),
                ],
                const SizedBox(height: 14),
                _footer(task),
              ],
            ),
          );
        },
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
            onPressed: () => context.push(
              TaskFormScreen.routeName,
              extra: <String, dynamic>{'taskCode': task.code},
            ),
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

  Widget _scheduleCard(Task task) {
    final effort = TaskUiUtils.effortLabel(task.effort);
    return _sectionCard(
      title: 'Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(
            Icons.play_circle_outline,
            'Starts',
            '${DateFormat('EEE, MMM d, yyyy').format(task.startDate)}'
                ' • ${TaskUiUtils.formatTime(task.startTime)}',
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.flag_outlined,
            'Due',
            '${DateFormat('EEE, MMM d, yyyy').format(task.dueDate)}'
                ' • ${TaskUiUtils.formatTime(task.dueTime)}',
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

  Widget _attachmentCard(BuildContext context, Task task) {
    return _sectionCard(
      title: 'Attachment',
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18, color: AppColors.themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.attachmentName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => CoreUtils.showTopSnackBar(
              context: context,
              message: 'Attachment preview is not available offline',
              isWarning: true,
            ),
            child: const Text('Open', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
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
