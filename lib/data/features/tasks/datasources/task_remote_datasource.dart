import 'package:dio/dio.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/tasks/entities/task.dart';
import '../../../../domain/features/tasks/entities/task_assignee.dart';
import '../../../../domain/features/tasks/entities/task_attachment.dart';
import '../../../../domain/features/tasks/entities/task_board.dart';
import '../../../../domain/features/tasks/entities/task_occurrence.dart';
import '../../../../domain/features/tasks/entities/task_query.dart';
import '../../../../domain/features/tasks/entities/task_series.dart';
import '../../../../domain/features/tasks/entities/task_upload_session.dart';
import '../models/task_models.dart';

/// Talks to the Tasks API on the events-todo microservice (`/api/v1/tasks`).
/// Org/school scoping headers are attached globally by `AuthInterceptor`, so
/// nothing tenant-specific is set here.
abstract class TaskRemoteDataSource {
  /// `GET /api/v1/tasks/assignments` — one page of assignment cards, filtered
  /// by [query] (Tasks API §7). The repository pages through these to build the
  /// flat list the cubit groups client-side.
  Future<List<TaskAssignmentModel>> getAssignments(TaskQuery query);

  /// `GET /api/v1/tasks` — one page of the task-series list (Tasks API §2).
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? q,
    int page,
    int size,
  });

  /// `GET /api/v1/tasks/{code}` — full detail for one series (Tasks API §2a),
  /// including the recurrence breakdown the lean list rows omit.
  Future<TaskSeriesModel> getTask(String code);

  /// `GET /api/v1/tasks/board` — Kanban board grouped into status columns, each
  /// independently paginated (Tasks API §6).
  Future<TaskBoard> getBoard(TaskQuery query);

  /// `POST /api/v1/tasks` — create a series and its roster.
  Future<TaskSeriesModel> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes,
  });

  /// `PATCH /api/v1/tasks/{code}` — partial series update / roster replace.
  /// [schedule], when non-null, carries the recurrence rule and series
  /// dates/times to persist (Tasks API §3 full parity). [assetCodes], when
  /// non-null, full-replaces attachments; [parentTaskCode] re-parents (`""`
  /// clears an existing parent). [scope] defaults to `ALL`; pass
  /// `THIS_AND_FUTURE` with [anchorOccurrenceCode] to reanchor the schedule
  /// regeneration at a specific occurrence (§3d).
  Future<TaskSeriesModel> updateTask({
    required String code,
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

  /// `DELETE /api/v1/tasks/{code}` — soft-delete the series.
  Future<void> deleteTask(String code);

  /// `DELETE /api/v1/tasks/{code}/assignees/{staffCode}` — remove one assignee
  /// from the roster without touching the series or anyone else (Tasks API §4a).
  Future<void> removeAssignee({
    required String code,
    required String staffCode,
  });

  /// `PATCH /api/v1/tasks/{code}/assignees/{staffCode}` — update one assignee's
  /// priority in isolation, cascading it onto their future assignments without
  /// resending the whole roster (Tasks API §4b).
  Future<void> updateAssigneePriority({
    required String code,
    required String staffCode,
    required TaskPriority priority,
  });

  /// `PATCH /api/v1/tasks/assignments/{code}/status` — change one card's status.
  Future<TaskAssignmentModel> updateAssignmentStatus({
    required String code,
    required TaskStatus status,
  });

  /// `GET /api/v1/tasks/assignments/{code}` — one assignment by its own code
  /// (Tasks API §5a).
  Future<TaskAssignmentModel> getAssignment(String code);

  /// `PATCH /api/v1/tasks/assignments/{code}` — edit a single assignment
  /// (Tasks API §5b). Accepts the full create-time field set; the occurrence's
  /// own schedule travels as discrete `occurrenceDate`/`startTime`/`dueDate`/
  /// `dueTime` fields. Every field is optional so callers send only what
  /// changed. The edit form funnels its whole save through here.
  Future<TaskAssignmentModel> updateAssignment({
    required String code,
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

  /// `DELETE /api/v1/tasks/assignments/{code}` — remove one occurrence for one
  /// assignee (must be `TO_DO`) (Tasks API §5c).
  Future<void> deleteAssignment(String code);

  /// `GET /api/v1/tasks/{code}/occurrences` — every occurrence of one series,
  /// ascending (Tasks API §11a).
  Future<List<TaskOccurrence>> getOccurrences(String code);

  /// `GET /api/v1/tasks/{code}/occurrences/{occurrenceCode}` — one occurrence's
  /// own detail (Tasks API §11b).
  Future<TaskOccurrence> getOccurrence({
    required String code,
    required String occurrenceCode,
  });

  /// `PATCH /api/v1/tasks/{code}/occurrences/{occurrenceCode}?scope=THIS_ONLY`
  /// — reschedule/override one occurrence only (Tasks API §11c).
  Future<TaskOccurrence> updateOccurrence({
    required String code,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  });

  /// `DELETE /api/v1/tasks/{code}/occurrences/{occurrenceCode}` — cancel one
  /// occurrence, keeping its row/history (Tasks API §11d).
  Future<TaskOccurrence> cancelOccurrence({
    required String code,
    required String occurrenceCode,
    String? reason,
  });

  /// `POST /api/v1/tasks/upload-session` — open a school-wide shared upload
  /// session for task attachments (Tasks API §8).
  Future<TaskUploadSession> createUploadSession();

  /// `GET /api/v1/tasks/{code}/attachments` — the series' current attachments.
  /// Empty list when the endpoint is absent (see [ApiPaths.taskAttachments]).
  Future<List<TaskAttachment>> getAttachments(String code);

  /// `DELETE /api/v1/tasks/{code}/attachments/{attachmentCode}`.
  Future<void> deleteAttachment({
    required String code,
    required String attachmentCode,
  });
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._client, this._storage);

  final Dio _client;
  final StorageService _storage;

  /// `POST /api/v1/tasks` needs `X-Staff-Code` — the logged-in user's staff
  /// code, used as `assignedBy` on the `TASK_ASSIGNED` notification (Tasks API
  /// header table). Org/school scoping headers are attached globally by
  /// `AuthInterceptor`; this one is create-specific so it lives here and is
  /// only sent when [withStaffCode] is set.
  Future<Options> _options({
    bool withStaffCode = false,
    bool multiList = false,
  }) async {
    final headers = <String, dynamic>{};
    if (withStaffCode) {
      final staffCode =
          (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
      if (staffCode.isNotEmpty) headers['X-Staff-Code'] = staffCode;
    }
    return Options(
      headers: headers.isEmpty ? null : headers,
      // Repeated multi-select params (`assigneeCodes`, `priorities`,
      // `statuses`) must serialize as `key=a&key=b`, not `key[]=…`.
      listFormat: multiList ? ListFormat.multi : null,
    );
  }

  String _url(String path) => ApiPaths.urlWithBase(
        path,
        ApiConstants.eventsTodoBaseUrl,
      );

  @override
  Future<List<TaskAssignmentModel>> getAssignments(TaskQuery query) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.taskAssignments),
      queryParameters: TaskRequestBuilder.assignmentQueryParams(query),
      options: await _options(multiList: true),
    );
    return _parseAssignmentList(response.data);
  }

  @override
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? q,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.tasks),
      queryParameters: TaskRequestBuilder.seriesListQueryParams(
        seriesStatus: seriesStatus,
        recurring: recurring,
        q: q,
        page: page,
        size: size,
      ),
      options: await _options(),
    );
    return TaskResponseParser.seriesPage(response.data);
  }

  @override
  Future<TaskBoard> getBoard(TaskQuery query) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.taskBoard),
      queryParameters: TaskRequestBuilder.assignmentQueryParams(query),
      options: await _options(multiList: true),
    );
    return TaskResponseParser.board(response.data);
  }

  @override
  Future<TaskSeriesModel> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) async {
    final response = await _client.post<dynamic>(
      _url(ApiPaths.tasks),
      data: TaskRequestBuilder.createBody(
        draft: draft,
        assignees: assignees,
        holidayPolicy: holidayPolicy,
        assetCodes: assetCodes,
      ),
      options: await _options(withStaffCode: true),
    );
    return _parseSeries(response.data, action: 'create');
  }

  @override
  Future<TaskSeriesModel> updateTask({
    required String code,
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
    // Only send `scope`/`anchorOccurrenceCode` for THIS_AND_FUTURE (§3d) — a
    // plain whole-series edit stays on the server default (ALL) and keeps the
    // request identical to the pre-scope behaviour.
    final query = <String, dynamic>{};
    if (scope == TaskUpdateScope.thisAndFuture) {
      query['scope'] = scope.value;
      final anchor = (anchorOccurrenceCode ?? '').trim();
      if (anchor.isNotEmpty) query['anchorOccurrenceCode'] = anchor;
    }
    final response = await _client.patch<dynamic>(
      _url(ApiPaths.taskByCode(code)),
      data: TaskRequestBuilder.updateBody(
        title: title,
        description: description,
        holidayPolicy: holidayPolicy,
        schedule: schedule,
        assignees: assignees,
        assetCodes: assetCodes,
        parentTaskCode: parentTaskCode,
      ),
      queryParameters: query.isEmpty ? null : query,
      options: await _options(),
    );
    return _parseSeries(response.data, action: 'update');
  }

  @override
  Future<TaskSeriesModel> getTask(String code) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.taskByCode(code)),
      options: await _options(),
    );
    return _parseSeries(response.data, action: 'fetch');
  }

  @override
  Future<void> deleteTask(String code) async {
    try {
      await _client.delete<dynamic>(
        _url(ApiPaths.taskByCode(code)),
        options: await _options(),
      );
    } on DioException catch (e) {
      // Already deleted on the server → treat as success (idempotent), so a
      // stale card can still be cleared from the board instead of erroring.
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  @override
  Future<void> removeAssignee({
    required String code,
    required String staffCode,
  }) async {
    await _client.delete<dynamic>(
      _url(ApiPaths.taskAssignee(code, staffCode)),
      options: await _options(),
    );
  }

  @override
  Future<void> updateAssigneePriority({
    required String code,
    required String staffCode,
    required TaskPriority priority,
  }) async {
    await _client.patch<dynamic>(
      _url(ApiPaths.taskAssignee(code, staffCode)),
      data: TaskRequestBuilder.assigneePriorityBody(priority),
      options: await _options(),
    );
  }

  @override
  Future<TaskAssignmentModel> updateAssignmentStatus({
    required String code,
    required TaskStatus status,
  }) async {
    final response = await _client.patch<dynamic>(
      _url(ApiPaths.taskAssignmentStatus(code)),
      data: TaskRequestBuilder.statusBody(status),
      options: await _options(),
    );
    return _parseAssignmentSingle(response.data);
  }

  @override
  Future<TaskAssignmentModel> getAssignment(String code) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.taskAssignmentByCode(code)),
      options: await _options(),
    );
    return _parseAssignmentSingle(response.data);
  }

  @override
  Future<TaskAssignmentModel> updateAssignment({
    required String code,
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
    final response = await _client.patch<dynamic>(
      _url(ApiPaths.taskAssignmentByCode(code)),
      data: TaskRequestBuilder.assignmentPatchBody(
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
      ),
      options: await _options(),
    );
    return _parseAssignmentSingle(response.data);
  }

  @override
  Future<void> deleteAssignment(String code) async {
    await _client.delete<dynamic>(
      _url(ApiPaths.taskAssignmentByCode(code)),
      options: await _options(),
    );
  }

  @override
  Future<List<TaskOccurrence>> getOccurrences(String code) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.taskOccurrences(code)),
      options: await _options(),
    );
    return TaskResponseParser.occurrenceList(response.data);
  }

  @override
  Future<TaskOccurrence> getOccurrence({
    required String code,
    required String occurrenceCode,
  }) async {
    final response = await _client.get<dynamic>(
      _url(ApiPaths.taskOccurrence(code, occurrenceCode)),
      options: await _options(),
    );
    return TaskResponseParser.occurrence(response.data);
  }

  @override
  Future<TaskOccurrence> updateOccurrence({
    required String code,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) async {
    final response = await _client.patch<dynamic>(
      _url(ApiPaths.taskOccurrence(code, occurrenceCode)),
      // THIS_ONLY is the only value this endpoint accepts and its default, so
      // send it explicitly for clarity (§11c).
      queryParameters: const {'scope': 'THIS_ONLY'},
      data: TaskRequestBuilder.occurrencePatchBody(
        scheduledStartDate: scheduledStartDate,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        overrideTitle: overrideTitle,
        overrideDescription: overrideDescription,
      ),
      options: await _options(),
    );
    return TaskResponseParser.occurrence(response.data);
  }

  @override
  Future<TaskOccurrence> cancelOccurrence({
    required String code,
    required String occurrenceCode,
    String? reason,
  }) async {
    final trimmedReason = (reason ?? '').trim();
    final response = await _client.delete<dynamic>(
      _url(ApiPaths.taskOccurrence(code, occurrenceCode)),
      queryParameters:
          trimmedReason.isEmpty ? null : {'reason': trimmedReason},
      options: await _options(),
    );
    return TaskResponseParser.occurrence(response.data);
  }

  @override
  Future<TaskUploadSession> createUploadSession() async {
    final response = await _client.post<dynamic>(
      _url(ApiPaths.taskUploadSession),
      options: await _options(),
    );
    return TaskResponseParser.uploadSession(
      response.data,
      fallbackDocumentBasePath:
          ApiConstants.isUat ? '/api/v1/document' : '/document-ms/api/v1',
    );
  }

  @override
  Future<List<TaskAttachment>> getAttachments(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return const <TaskAttachment>[];
    try {
      final response = await _client.get<dynamic>(
        _url(ApiPaths.taskAttachments(trimmed)),
        options: await _options(),
      );
      return TaskResponseParser.attachmentList(response.data);
    } on DioException catch (e) {
      // The Tasks service documents only the write side of attachments, so a
      // deployment without the read endpoint is expected. Surface that as
      // "unavailable" rather than "none": the two must not be confused,
      // because `assetCodes` is a full replace on save.
      final status = e.response?.statusCode ?? 0;
      if (status == 404 || status == 405 || status == 501) {
        throw const TaskAttachmentsUnavailable();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteAttachment({
    required String code,
    required String attachmentCode,
  }) async {
    await _client.delete<dynamic>(
      _url(ApiPaths.taskAttachment(code, attachmentCode)),
      options: await _options(),
    );
  }

  static List<TaskAssignmentModel> _parseAssignmentList(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const <TaskAssignmentModel>[];
    final data = raw['data'];
    final items = data is Map<String, dynamic> ? data['items'] : data;
    if (items is! List) return const <TaskAssignmentModel>[];

    final result = <TaskAssignmentModel>[];
    for (final entry in items) {
      if (entry is! Map) continue;
      final model = TaskAssignmentModel.fromJson(
        entry.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (model.code.isNotEmpty) result.add(model);
    }
    return result;
  }

  static TaskSeriesModel _parseSeries(dynamic raw, {required String action}) {
    final data = _requireData(raw, action: action);
    return TaskSeriesModel.fromJson(data);
  }

  static TaskAssignmentModel _parseAssignmentSingle(dynamic raw) {
    final data = _requireData(raw, action: 'status update');
    return TaskAssignmentModel.fromJson(data);
  }

  static Map<String, dynamic> _requireData(dynamic raw,
      {required String action}) {
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected task $action API response format');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload in task $action response');
    }
    return data;
  }
}
