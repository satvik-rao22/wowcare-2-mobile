import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// One actionable item in the [TodoCard] checklist.
class _TodoTask {
  _TodoTask({
    required this.name,
    required this.dueDate,
    required this.assignee,
    this.done = false,
  });

  final String name;
  final String dueDate;
  final String assignee;
  bool done;
}

/// "To-do" card — a checklist of pending admin tasks.
///
/// UI-only: the task list is hardcoded mock data; checkboxes toggle local
/// state only.
class TodoCard extends StatefulWidget {
  const TodoCard({super.key});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _minimized = false;

  final List<_TodoTask> _tasks = [
    _TodoTask(
      name: 'Send Invoices',
      dueDate: 'Nov 06',
      assignee: 'Emma Wilson',
      done: true,
    ),
    _TodoTask(
      name: 'Create Newsletters',
      dueDate: 'Nov 14',
      assignee: 'Olivia Brown',
    ),
    _TodoTask(
      name: 'Generate Reports',
      dueDate: 'Nov 24',
      assignee: 'Sophia Davis',
    ),
    _TodoTask(
      name: 'Staff Scheduling - Dec 2024',
      dueDate: 'Nov 30',
      assignee: 'Ava Miller',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: SkeuRadius.xxl,
      padding: const EdgeInsets.all(12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardCardHeader(
            title: 'To-do',
            showRedirect: true,
            onRedirect: () {},
            minimized: _minimized,
            onToggle: () => setState(() => _minimized = !_minimized),
          ),
          if (!_minimized) ...[
            const SizedBox(height: 12),
            for (final task in _tasks) _buildTaskRow(task),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskRow(_TodoTask task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CustomCheckbox(
            value: task.done,
            onChanged: (_) => setState(() => task.done = !task.done),
          ),
          const SizedBox(width: 8),
          // Task name — tapping it also toggles completion.
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => task.done = !task.done),
              child: Text(
                task.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  decoration: task.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.access_time, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 4),
          Text(
            task.dueDate,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),
          DocumentImageWidget(
            fileUuid: '',
            name: task.assignee,
            size: 36,
            fontSize: 14,
            disableProfileLookupFallback: true,
            disableAttendanceStatusLookup: true,
          ),
        ],
      ),
    );
  }
}
