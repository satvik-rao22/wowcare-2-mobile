import 'package:flutter/material.dart';

import '../../../../../core/common/widgets/custom_checkbox.dart';
import '../../../../../core/common/widgets/gradient_toggle_button.dart';
import '../../../../../core/res/colors.dart';

class TodoCard extends StatefulWidget {
  const TodoCard({super.key});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To-do',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(254, 241, 195, 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: Color.fromRGBO(137, 108, 2, 1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GradientToggleButton(
                    minimized: _minimized,
                    onTap: () {
                      setState(() {
                        _minimized = !_minimized;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (!_minimized) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                TaskItem(
                  isChecked: true,
                  taskName: 'Send Invoices',
                  dueDate: 'Nov 06',
                  avatarUrl: 'https://randomuser.me/api/portraits/women/72.jpg',
                  onChanged: (isChecked) {},
                ),
                TaskItem(
                  isChecked: false,
                  taskName: 'Create Newsletters',
                  dueDate: 'Nov 14',
                  avatarUrl: 'https://randomuser.me/api/portraits/women/93.jpg',
                  onChanged: (isChecked) {},
                ),
                TaskItem(
                  isChecked: false,
                  taskName: 'Generate Reports',
                  dueDate: 'Nov 24',
                  avatarUrl: 'https://randomuser.me/api/portraits/women/50.jpg',
                  onChanged: (isChecked) {},
                ),
                TaskItem(
                  isChecked: false,
                  taskName: 'Staff Scheduling- Dec 2024',
                  dueDate: 'Nov 31',
                  avatarUrl: 'https://randomuser.me/api/portraits/women/57.jpg',
                  onChanged: (isChecked) {},
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.isChecked,
    required this.taskName,
    required this.dueDate,
    required this.avatarUrl,
    required this.onChanged,
  });

  final bool isChecked;
  final String taskName;
  final String dueDate;
  final String avatarUrl;
  final Function(bool isChecked) onChanged;
  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomCheckbox(
            value: isChecked,
            onChanged: (val) {
              setState(() {
                isChecked = !isChecked;
              });
            },
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isChecked = !isChecked;
                      });
                    },
                    child: Text(
                      widget.taskName,
                      style: TextStyle(
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationThickness: 3,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Icon(
                  Icons.access_time,
                  color: Colors.grey.shade600,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  widget.dueDate,
                  style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8.0),
                CircleAvatar(
                  radius: 18.0,
                  backgroundImage: NetworkImage(widget.avatarUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
