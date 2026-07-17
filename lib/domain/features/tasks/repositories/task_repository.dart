import '../entities/task.dart';
import '../entities/task_assignee.dart';

/// Tasks are backed by the events-todo microservice. A [Task] here is one
/// **task assignment** card (one person on one occurrence); create/update/
/// delete act on the owning **series**, while status changes act on the
/// single assignment (Tasks API §5).
abstract class TaskRepository {
  /// Flat, mixed-status page of task assignments mapped to [Task] cards
  /// (Tasks API §7 `GET /tasks/assignments`). [query] is the server-side
  /// free-text search filter.
  Future<List<Task>> getTasks({String? query});

  /// Creates one task series with its roster (Tasks API §1 `POST /tasks`).
  /// The response carries the series, not the per-assignee assignment codes,
  /// so callers reload [getTasks] to pick up the new cards.
  Future<void> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
  });

  /// Partial update of series-level fields and/or a full-replace roster
  /// (Tasks API §3 `PATCH /tasks/{code}`, full create/update parity). Pass
  /// [schedule] to persist the recurrence rule and series dates/times —
  /// changing those re-materializes future occurrences, so only supply it when
  /// the schedule actually changed.
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
  });

  /// Soft-deletes the series and its untouched future assignments
  /// (Tasks API §4 `DELETE /tasks/{code}`).
  Future<void> deleteTask(String seriesCode);

  /// Quick status change on a single assignment (Tasks API §5
  /// `PATCH /tasks/assignments/{code}/status`). Returns the updated card.
  Future<Task> updateAssignmentStatus({
    required String assignmentCode,
    required TaskStatus status,
  });
}
