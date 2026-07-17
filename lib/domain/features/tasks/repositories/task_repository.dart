import '../entities/task.dart';
import '../entities/task_assignee.dart';
import '../entities/task_board.dart';
import '../entities/task_query.dart';
import '../entities/task_series.dart';

/// Tasks are backed by the events-todo microservice. A [Task] here is one
/// **task assignment** card (one person on one occurrence); create/update/
/// delete act on the owning **series**, while status changes act on the
/// single assignment (Tasks API §5).
abstract class TaskRepository {
  /// Flat, mixed-status list of task assignments mapped to [Task] cards
  /// (Tasks API §7 `GET /tasks/assignments`). [query] is the server-side
  /// free-text search filter. Pages through the endpoint internally so the
  /// full result set is returned, not just the first page.
  Future<List<Task>> getTasks({String? query});

  /// One page of the task-series list (Tasks API §2 `GET /tasks`).
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? query,
    int page,
    int size,
  });

  /// The Kanban board grouped into status columns (Tasks API §6
  /// `GET /tasks/board`), each column independently paginated by [query].
  Future<TaskBoard> getBoard(TaskQuery query);

  /// Creates one task series with its roster (Tasks API §1 `POST /tasks`).
  /// The response carries the series, not the per-assignee assignment codes,
  /// so callers reload [getTasks] to pick up the new cards. [assetCodes] are
  /// attachment codes from the upload-session flow (§8/§9).
  Future<void> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes,
  });

  /// Partial update of series-level fields and/or a full-replace roster
  /// (Tasks API §3 `PATCH /tasks/{code}`, full create/update parity). Pass
  /// [schedule] to persist the recurrence rule and series dates/times.
  /// [assetCodes], when present, full-replaces attachments; [parentTaskCode]
  /// re-parents (`""` clears an existing parent).
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
    String? parentTaskCode,
  });

  /// Soft-deletes the series and its untouched future assignments
  /// (Tasks API §4 `DELETE /tasks/{code}`).
  Future<void> deleteTask(String seriesCode);

  /// Removes one assignee from a task's roster without touching the series or
  /// anyone else (Tasks API §4a `DELETE /tasks/{code}/assignees/{staffCode}`).
  Future<void> removeAssignee({
    required String seriesCode,
    required String staffCode,
  });

  /// Quick status change on a single assignment (Tasks API §5
  /// `PATCH /tasks/assignments/{code}/status`). Returns the updated card.
  Future<Task> updateAssignmentStatus({
    required String assignmentCode,
    required TaskStatus status,
  });

  /// Opens a shared upload session for task attachments and drives the full
  /// cross-service upload of [filePath], returning the ready asset code to pass
  /// to [createTask]/[updateTask] (Tasks API §8/§9).
  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    required String contentType,
  });
}
