import '../entities/task.dart';
import '../entities/task_assignee.dart';
import '../entities/task_attachment.dart';
import '../entities/task_board.dart';
import '../entities/task_occurrence.dart';
import '../entities/task_query.dart';
import '../entities/task_series.dart';
import '../entities/task_upload_session.dart';

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

  /// Full detail for one series, including the recurrence breakdown the flat
  /// assignment cards omit (Tasks API §2a `GET /tasks/{code}`). Lets the edit
  /// form pre-populate an existing series' recurrence.
  Future<TaskSeries> getTask(String seriesCode);

  /// The Kanban board grouped into status columns (Tasks API §6
  /// `GET /tasks/board`), each column independently paginated by [query].
  Future<TaskBoard> getBoard(TaskQuery query);

  /// Creates one task series with its roster (Tasks API §1 `POST /tasks`) and
  /// returns the new series' `TSK_…` code. The response carries the series, not
  /// the per-assignee assignment codes, so callers still reload [getTasks] to
  /// pick up the new cards — but the returned code is what lets them address
  /// the series straight away (e.g. to prime its attachment cache) without
  /// hunting for it in the reloaded list. [assetCodes] are attachment codes
  /// from the upload-session flow (§8/§9).
  Future<String> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes,
  });

  /// Partial update of series-level fields and/or a full-replace roster
  /// (Tasks API §3 `PATCH /tasks/{code}`, full create/update parity). Pass
  /// [schedule] to persist the recurrence rule and series dates/times.
  /// [assetCodes], when present, full-replaces attachments; [parentTaskCode]
  /// re-parents (`""` clears an existing parent). [scope]/[anchorOccurrenceCode]
  /// select `THIS_AND_FUTURE` reanchoring (§3d); the default is whole-series
  /// (`ALL`).
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
    String? parentTaskCode,
    TaskUpdateScope scope,
    String? anchorOccurrenceCode,
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

  /// Updates one assignee's priority in isolation, cascading it onto their
  /// future assignments without resending the whole roster (Tasks API §4b
  /// `PATCH /tasks/{code}/assignees/{staffCode}`).
  Future<void> updateAssigneePriority({
    required String seriesCode,
    required String staffCode,
    required TaskPriority priority,
  });

  /// Quick status change on a single assignment (Tasks API §5
  /// `PATCH /tasks/assignments/{code}/status`). Returns the updated card.
  Future<Task> updateAssignmentStatus({
    required String assignmentCode,
    required TaskStatus status,
  });

  /// One assignment fetched by its own code (Tasks API §5a
  /// `GET /tasks/assignments/{code}`).
  Future<Task> getAssignment(String assignmentCode);

  /// Edits a single assignment by its own code (Tasks API §5b
  /// `PATCH /tasks/assignments/{code}`). Accepts the full create-time field set;
  /// the occurrence's own schedule travels as discrete occurrenceDate/startTime/
  /// dueDate/dueTime. Every field is optional (null = unchanged). Returns the
  /// updated card. The edit form routes its whole save through here.
  Future<Task> updateAssignment({
    required String assignmentCode,
    String? title,
    String? description,
    DateTime? occurrenceDate,
    String? startTime,
    DateTime? dueDate,
    String? dueTime,
    TaskPriority? priority,
    TaskStatus? status,
    double? effort,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
  });

  /// Removes one occurrence for one assignee — must be `TO_DO` (Tasks API §5c
  /// `DELETE /tasks/assignments/{code}`). Distinct from [removeAssignee], which
  /// drops the person from the whole roster.
  Future<void> deleteAssignment(String assignmentCode);

  /// Every occurrence of one series, ascending (Tasks API §11a
  /// `GET /tasks/{code}/occurrences`). The only source of occurrence codes.
  Future<List<TaskOccurrence>> getOccurrences(String seriesCode);

  /// One occurrence's own detail (Tasks API §11b).
  Future<TaskOccurrence> getOccurrence({
    required String seriesCode,
    required String occurrenceCode,
  });

  /// Reschedule/override one occurrence only — the series, other occurrences and
  /// other assignees are untouched (Tasks API §11c, THIS_ONLY).
  Future<TaskOccurrence> updateOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  });

  /// Cancels one occurrence, keeping its row/history (Tasks API §11d). Returns
  /// the cancelled occurrence.
  Future<TaskOccurrence> cancelOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    String? reason,
  });

  // SUPERSEDED by the shared `AttachmentUploadManager` (see
  // `UploadTaskAttachmentsUseCase`). Attachment transfer is no longer a
  // repository concern: the repo now only opens the session
  // ([createUploadSession]) and the manager drives presign/PUT/complete.
  //
  // Replaced because this contract forced a per-file loop — one presign per
  // file, whole files buffered in memory, and an all-or-nothing result.
  //
  // /// Opens **one** shared upload session and drives every file in [files]
  // /// through it (Tasks API §8/§9), returning their ready asset codes in the
  // /// same order — ready to pass to [createTask]/[updateTask]'s `assetCodes`.
  // ///
  // /// [alreadyUploaded] maps a file path to an asset code from a previous
  // /// attempt; those files are skipped so a retry after a partial failure never
  // /// re-uploads bytes that already landed. [onAssetUploaded] fires as each file
  // /// completes so the caller can record it for exactly that purpose, and
  // /// [onProgress] reports 0-100 for the file at [index].
  // Future<List<String>> uploadAttachments({
  //   required List<PendingTaskAttachment> files,
  //   Map<String, String> alreadyUploaded = const {},
  //   void Function(String filePath, String assetCode)? onAssetUploaded,
  //   void Function(int index, int percent)? onProgress,
  // });


  /// The task series' current attachments. Returns an empty list — rather than
  /// throwing — when the backend has no attachments endpoint yet, so the rest
  /// of the task UI keeps working.
  Future<List<TaskAttachment>> getAttachments(String taskCode);

  /// Detaches one attachment from the series by its attachment code.
  Future<void> detachAttachment({
    required String taskCode,
    required String attachmentCode,
  });

  /// Opens a shared upload session for task attachments (Tasks API §8
  /// `POST /tasks/upload-session`) without uploading anything.
  ///
  /// Exposed so a multi-file upload can open one session and presign every file
  /// against it in a single batch, rather than repeating the whole round trip
  /// per file the way [uploadAttachment] does.
  Future<TaskUploadSession> createUploadSession();
}
