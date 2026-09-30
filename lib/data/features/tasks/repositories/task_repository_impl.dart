import 'package:wowcare/data/features/tasks/datasources/task_remote_datasource.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/entities/task_upload_session.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';

/// Remote-only implementation backed by the events-todo Tasks API. No Isar
/// persistence or mock seeding — mirrors the Events/Holidays modules.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  /// Page size used when exhausting the flat assignments endpoint. Kept modest
  /// so a small school pays for one round trip while a large one still loads
  /// completely across a bounded number of pages.
  static const int _assignmentPageSize = 100;

  /// Hard ceiling on pages walked (safety valve against a misbehaving server
  /// that never shortens a page) — 100 pages × 100 rows = 10k assignments.
  static const int _maxAssignmentPages = 100;

  @override
  Future<List<Task>> getTasks({String? query}) async {
    // Defensive de-duplication by assignment code: a single assignment must
    // never surface as two cards even if the API echoes a row twice or across
    // page boundaries.
    final seen = <String>{};
    final tasks = <Task>[];
    var page = 0;
    while (page < _maxAssignmentPages) {
      final models = await _remoteDataSource.getAssignments(
        TaskQuery(query: query, page: page, size: _assignmentPageSize),
      );
      for (final model in models) {
        if (seen.add(model.code)) tasks.add(model.toEntity());
      }
      if (models.length < _assignmentPageSize) break;
      page++;
    }
    return tasks
      ..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        if (byDue != 0) return byDue;
        return a.dueTime.compareTo(b.dueTime);
      });
  }

  @override
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? query,
    int page = 0,
    int size = 20,
  }) {
    return _remoteDataSource.getTaskSeries(
      seriesStatus: seriesStatus,
      recurring: recurring,
      q: query,
      page: page,
      size: size,
    );
  }

  @override
  Future<TaskSeries> getTask(String seriesCode) async {
    final model = await _remoteDataSource.getTask(seriesCode.trim());
    return model.toSeries();
  }

  @override
  Future<TaskBoard> getBoard(TaskQuery query) {
    return _remoteDataSource.getBoard(query);
  }

  @override
  Future<String> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) async {
    final series = await _remoteDataSource.createTask(
      draft: draft,
      assignees: assignees,
      holidayPolicy: holidayPolicy,
      assetCodes: assetCodes,
    );
    return series.code;
  }

  @override
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
    String? parentTaskCode,
    TaskUpdateScope scope = TaskUpdateScope.all,
    String? anchorOccurrenceCode,
  }) async {
    await _remoteDataSource.updateTask(
      code: seriesCode.trim(),
      title: title,
      description: description,
      holidayPolicy: holidayPolicy,
      schedule: schedule,
      assignees: assignees,
      assetCodes: assetCodes,
      parentTaskCode: parentTaskCode,
      scope: scope,
      anchorOccurrenceCode: anchorOccurrenceCode,
    );
  }

  @override
  Future<void> deleteTask(String seriesCode) {
    return _remoteDataSource.deleteTask(seriesCode.trim());
  }

  @override
  Future<void> removeAssignee({
    required String seriesCode,
    required String staffCode,
  }) {
    return _remoteDataSource.removeAssignee(
      code: seriesCode.trim(),
      staffCode: staffCode.trim(),
    );
  }

  @override
  Future<void> updateAssigneePriority({
    required String seriesCode,
    required String staffCode,
    required TaskPriority priority,
  }) {
    return _remoteDataSource.updateAssigneePriority(
      code: seriesCode.trim(),
      staffCode: staffCode.trim(),
      priority: priority,
    );
  }

  @override
  Future<Task> updateAssignmentStatus({
    required String assignmentCode,
    required TaskStatus status,
  }) async {
    final model = await _remoteDataSource.updateAssignmentStatus(
      code: assignmentCode.trim(),
      status: status,
    );
    return model.toEntity();
  }

  @override
  Future<Task> getAssignment(String assignmentCode) async {
    final model = await _remoteDataSource.getAssignment(assignmentCode.trim());
    return model.toEntity();
  }

  @override
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
  }) async {
    final model = await _remoteDataSource.updateAssignment(
      code: assignmentCode.trim(),
      title: title,
      description: description,
      occurrenceDate: occurrenceDate,
      startTime: startTime,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      status: status,
      effort: effort,
      schedule: schedule,
      assignees: assignees,
      assetCodes: assetCodes,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteAssignment(String assignmentCode) {
    return _remoteDataSource.deleteAssignment(assignmentCode.trim());
  }

  @override
  Future<List<TaskOccurrence>> getOccurrences(String seriesCode) {
    return _remoteDataSource.getOccurrences(seriesCode.trim());
  }

  @override
  Future<TaskOccurrence> getOccurrence({
    required String seriesCode,
    required String occurrenceCode,
  }) {
    return _remoteDataSource.getOccurrence(
      code: seriesCode.trim(),
      occurrenceCode: occurrenceCode.trim(),
    );
  }

  @override
  Future<TaskOccurrence> updateOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) {
    return _remoteDataSource.updateOccurrence(
      code: seriesCode.trim(),
      occurrenceCode: occurrenceCode.trim(),
      scheduledStartDate: scheduledStartDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      overrideTitle: overrideTitle,
      overrideDescription: overrideDescription,
    );
  }

  @override
  Future<TaskOccurrence> cancelOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    String? reason,
  }) {
    return _remoteDataSource.cancelOccurrence(
      code: seriesCode.trim(),
      occurrenceCode: occurrenceCode.trim(),
      reason: reason,
    );
  }

  @override
  Future<TaskUploadSession> createUploadSession() {
    return _remoteDataSource.createUploadSession();
  }

  // Attachment upload (presign → PUT → complete, batched) now runs entirely
  // through the shared `AttachmentUploadManager` rather than through this
  // repository: it batches the presign call, streams file transfers instead
  // of buffering them, and polls for "attachable" rather than the stricter
  // "ready" state that used to hang event saves. `TasksCubit.uploadAttachments`
  // calls the manager directly.

  @override
  Future<List<TaskAttachment>> getAttachments(String taskCode) {
    return _remoteDataSource.getAttachments(taskCode);
  }

  @override
  Future<void> detachAttachment({
    required String taskCode,
    required String attachmentCode,
  }) {
    return _remoteDataSource.deleteAttachment(
      code: taskCode.trim(),
      attachmentCode: attachmentCode.trim(),
    );
  }
}
