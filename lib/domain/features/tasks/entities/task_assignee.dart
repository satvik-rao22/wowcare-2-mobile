import 'package:equatable/equatable.dart';

import 'task.dart';

/// One entry in a task's roster (Tasks API `assignees[]`). A create/update
/// call sends a list of these; selecting several does not create N task rows —
/// it populates one shared roster (Tasks API §, "one task series + roster").
///
/// [priority] is optional: when set it overrides the task-level priority for
/// this person only; when null that person falls back to the task-level value.
class TaskAssignee extends Equatable {
  const TaskAssignee({
    required this.staffCode,
    this.priority,
  });

  final String staffCode;
  final TaskPriority? priority;

  @override
  List<Object?> get props => [staffCode, priority];
}
