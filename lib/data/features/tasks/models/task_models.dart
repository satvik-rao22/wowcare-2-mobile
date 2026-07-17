import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/entities/task_upload_session.dart';

/// DTO for a single **task assignment** — one person's card on one occurrence
/// (Tasks API §5–§7). This is the unit the board, the flat assignments list
/// and the status endpoint all return, and it maps 1:1 onto a UI [Task] card.
///
/// The assignment payload is intentionally lean: it carries no description,
/// effort, recurrence or creator, so [toEntity] leaves those at their entity
/// defaults. Series-level detail comes from [TaskSeriesModel].
class TaskAssignmentModel extends Equatable {
  const TaskAssignmentModel({
    required this.code,
    required this.taskCode,
    required this.title,
    this.assigneeCode = '',
    this.assigneeName = '',
    required this.occurrenceDate,
    required this.dueAt,
    this.priority = 'MEDIUM',
    this.status = 'TO_DO',
  });

  factory TaskAssignmentModel.fromJson(Map<String, dynamic> json) {
    final occurrence = _parseDate(json['occurrenceDate']) ?? DateTime.now();
    // `dueAt` is a full instant, usually UTC (`…17:00:00Z`). Convert to the
    // device's local zone before it is split into a local date/time downstream,
    // otherwise a 17:00Z due shows/compares as 17:00 local (off by the offset).
    final due = (_parseDate(json['dueAt']) ?? occurrence).toLocal();
    return TaskAssignmentModel(
      code: (json['code'] ?? '').toString().trim(),
      taskCode: (json['taskCode'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString(),
      assigneeCode: (json['assigneeCode'] ?? '').toString().trim(),
      // Not part of the documented assignment payload; parsed opportunistically
      // so cards show a name if the backend ever denormalizes one.
      assigneeName: (json['assigneeName'] ?? '').toString(),
      occurrenceDate: occurrence,
      dueAt: due,
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      status: (json['status'] ?? 'TO_DO').toString(),
    );
  }

  final String code;
  final String taskCode;
  final String title;
  final String assigneeCode;
  final String assigneeName;
  final DateTime occurrenceDate;
  final DateTime dueAt;
  final String priority;
  final String status;

  Task toEntity() {
    return Task(
      code: code,
      taskCode: taskCode,
      title: title,
      assigneeCode: assigneeCode,
      assigneeName: assigneeName,
      status: TaskStatus.fromValue(status),
      priority: TaskPriority.fromValue(priority),
      startDate: occurrenceDate,
      dueDate: DateTime(dueAt.year, dueAt.month, dueAt.day),
      dueTime: _formatTime(dueAt),
      createdAt: occurrenceDate,
      updatedAt: occurrenceDate,
    );
  }

  @override
  List<Object?> get props =>
      [code, taskCode, title, assigneeCode, occurrenceDate, dueAt, priority, status];
}

/// DTO for a **task series** — the row returned by create/update/list
/// (Tasks API §1–§3). Carries series-level fields; the per-assignee cards live
/// in [TaskAssignmentModel]. Parsed mainly to confirm a write succeeded.
class TaskSeriesModel extends Equatable {
  const TaskSeriesModel({
    required this.code,
    required this.title,
    this.description = '',
    this.recurringFlag = false,
    this.rruleFreq,
    this.seriesStartDate,
    this.seriesStatus = 'ACTIVE',
    this.nextOccurrenceDate,
    this.nextOccurrenceStatus = '',
    this.assigneeCount = 0,
    this.version = 0,
  });

  factory TaskSeriesModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic raw) {
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return TaskSeriesModel(
      code: (json['code'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      recurringFlag: json['recurringFlag'] == true,
      rruleFreq: (json['rruleFreq'] ?? '').toString().trim().isEmpty
          ? null
          : json['rruleFreq'].toString(),
      seriesStartDate: _parseDate(json['seriesStartDate']),
      seriesStatus: (json['seriesStatus'] ?? 'ACTIVE').toString(),
      nextOccurrenceDate: _parseDate(json['nextOccurrenceDate']),
      nextOccurrenceStatus: (json['nextOccurrenceStatus'] ?? '').toString(),
      assigneeCount: parseInt(json['assigneeCount']),
      version: parseInt(json['version']),
    );
  }

  final String code;
  final String title;
  final String description;
  final bool recurringFlag;
  final String? rruleFreq;
  final DateTime? seriesStartDate;
  final String seriesStatus;
  final DateTime? nextOccurrenceDate;
  final String nextOccurrenceStatus;
  final int assigneeCount;
  final int version;

  /// Maps the list DTO to its domain [TaskSeries] (Tasks API §2).
  TaskSeries toSeries() => TaskSeries(
        code: code,
        title: title,
        recurring: recurringFlag,
        recurrencePattern: TaskRecurrence.fromValue(rruleFreq),
        seriesStartDate: seriesStartDate,
        seriesStatus: TaskSeriesStatus.fromValue(seriesStatus),
        nextOccurrenceDate: nextOccurrenceDate,
        nextOccurrenceStatus: nextOccurrenceStatus,
        version: version,
      );

  @override
  List<Object?> get props => [code, title, seriesStatus, assigneeCount, version];
}

/// Builds the JSON bodies the Tasks API expects. Kept separate from the DTOs
/// so request shaping (which fields to send, wire formats) lives in one place.
abstract final class TaskRequestBuilder {
  /// `YYYY-MM-DD` — the wire format for series dates.
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Body for `POST /api/v1/tasks` (create a series + roster). Sends the
  /// recurrence fields for a recurring task and the concrete start/due dates
  /// for a one-off; `startTime`/`dueTime` are always sent (BR: defaults apply
  /// server-side when omitted, but the form always supplies them).
  static Map<String, dynamic> createBody({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) {
    final body = <String, dynamic>{
      'title': draft.title,
      if (draft.description.isNotEmpty) 'description': draft.description,
      'priority': draft.priority.value,
      'effort': draft.effort,
      if (holidayPolicy != null) 'holidayPolicy': holidayPolicy.value,
      'assignees': assignees.map(_assigneeJson).toList(),
      ..._scheduleJson(draft),
    };

    if (assetCodes.isNotEmpty) body['assetCodes'] = assetCodes;
    return body;
  }

  /// Body for `PATCH /api/v1/tasks/{code}`. Every field is optional; an
  /// omitted field means "leave unchanged" (Tasks API §3, full create/update
  /// parity). `assignees`, when present, is a full-replace roster; [schedule],
  /// when present, contributes the recurrence rule and series dates/times —
  /// changing those cascades away and re-materializes future occurrences, so
  /// callers should only pass it when the schedule actually changed.
  static Map<String, dynamic> updateBody({
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
    String? parentTaskCode,
  }) {
    return <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (holidayPolicy != null) 'holidayPolicy': holidayPolicy.value,
      if (schedule != null) ..._scheduleJson(schedule),
      if (assignees != null)
        'assignees': assignees.map(_assigneeJson).toList(),
      // Full-replace of attachments when present (§3c) — an empty list clears
      // them all.
      if (assetCodes != null) 'assetCodes': assetCodes,
      // Re-parent when present; an empty string clears an existing parent (§3c).
      // Checked against null (not emptiness) so `""` reaches the wire.
      if (parentTaskCode != null) 'parentTaskCode': parentTaskCode,
    };
  }

  /// The recurrence rule and series dates/times, shared by create and update.
  /// A recurring task sends its RRULE fields and lets the server roll the start
  /// forward; a one-off sends concrete `startDate`/`dueDate`. `startTime`/
  /// `dueTime` are always sent (the form always supplies them; defaults apply
  /// server-side when omitted).
  static Map<String, dynamic> _scheduleJson(Task task) {
    final json = <String, dynamic>{
      'recurring': task.recurring,
      'startTime': task.startTime,
      'dueTime': task.dueTime,
    };

    if (task.recurring) {
      final freq = task.recurringPattern ?? TaskRecurrence.daily;
      json['rruleFreq'] = freq.value;
      if (freq == TaskRecurrence.weekly && task.startDay != null) {
        json['rruleByDay'] = [_weekdayAbbr(task.startDay!)];
      }
      if (freq == TaskRecurrence.monthly && task.startDay != null) {
        final day = int.tryParse(task.startDay!.trim());
        if (day != null) json['rruleByMonthday'] = day;
      }
      if (task.recurringEndDate != null) {
        json['rruleUntil'] = formatDate(task.recurringEndDate!);
      }
    } else {
      json['startDate'] = formatDate(task.startDate);
      json['dueDate'] = formatDate(task.dueDate);
    }
    return json;
  }

  /// Body for `PATCH /api/v1/tasks/assignments/{code}/status`.
  static Map<String, dynamic> statusBody(TaskStatus status) =>
      <String, dynamic>{'status': status.value};

  /// Query parameters shared by `GET /tasks/assignments` (§7) and
  /// `GET /tasks/board` (§6): assignee/priority/status multi-selects, a due-date
  /// window, an overdue flag, free-text `q`, and pagination. Empty collections /
  /// nulls are dropped so the wire carries only active filters.
  static Map<String, dynamic> assignmentQueryParams(TaskQuery query) {
    final params = <String, dynamic>{
      'page': query.page,
      'size': query.size,
    };
    if (query.assigneeCodes.isNotEmpty) {
      params['assigneeCodes'] = query.assigneeCodes;
    }
    if (query.priorities.isNotEmpty) {
      params['priorities'] = query.priorities.map((p) => p.value).toList();
    }
    if (query.statuses.isNotEmpty) {
      params['statuses'] = query.statuses.map((s) => s.value).toList();
    }
    if (query.fromDate != null) params['fromDate'] = formatDate(query.fromDate!);
    if (query.toDate != null) params['toDate'] = formatDate(query.toDate!);
    if (query.overdue != null) params['overdue'] = query.overdue;
    final q = (query.query ?? '').trim();
    if (q.isNotEmpty) params['q'] = q;
    return params;
  }

  /// Query parameters for the series list `GET /tasks` (§2). All optional.
  static Map<String, dynamic> seriesListQueryParams({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? q,
    int page = 0,
    int size = 20,
  }) {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (seriesStatus != null) params['seriesStatus'] = seriesStatus.value;
    if (recurring != null) params['recurring'] = recurring;
    final query = (q ?? '').trim();
    if (query.isNotEmpty) params['q'] = query;
    return params;
  }

  static Map<String, dynamic> _assigneeJson(TaskAssignee assignee) =>
      <String, dynamic>{
        'staffCode': assignee.staffCode,
        if (assignee.priority != null) 'priority': assignee.priority!.value,
      };

  /// Maps a full weekday name (the entity's weekly `startDay`, e.g. `MONDAY`)
  /// to the two-letter RRULE abbreviation the API expects (e.g. `MO`).
  static String _weekdayAbbr(String dayName) {
    final normalized = dayName.trim().toUpperCase();
    const map = <String, String>{
      'MONDAY': 'MO',
      'TUESDAY': 'TU',
      'WEDNESDAY': 'WE',
      'THURSDAY': 'TH',
      'FRIDAY': 'FR',
      'SATURDAY': 'SA',
      'SUNDAY': 'SU',
    };
    // Already an abbreviation? Pass it through; otherwise fall back to a
    // two-letter prefix so an unexpected value never produces an empty day.
    return map[normalized] ??
        (normalized.length >= 2 ? normalized.substring(0, 2) : normalized);
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

int _parseIntOr(dynamic raw, {int fallback = 0}) {
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? fallback;
}

/// Parses the Tasks API's paginated / grouped read envelopes into domain
/// objects. Kept separate from the DTOs so JSON-shape knowledge lives in the
/// data layer and the domain entities stay transport-agnostic.
abstract final class TaskResponseParser {
  /// `GET /tasks` (§2) → a page of [TaskSeries]. Tolerant of a bare list or a
  /// missing envelope so a malformed payload degrades to an empty page.
  static TaskSeriesPage seriesPage(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : raw;
    final items = data is Map<String, dynamic> ? data['items'] : data;
    final series = <TaskSeries>[];
    if (items is List) {
      for (final entry in items) {
        if (entry is! Map) continue;
        final model = TaskSeriesModel.fromJson(
          entry.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (model.code.isNotEmpty) series.add(model.toSeries());
      }
    }
    final envelope = data is Map<String, dynamic> ? data : const {};
    return TaskSeriesPage(
      items: series,
      page: _parseIntOr(envelope['page']),
      size: _parseIntOr(envelope['size'], fallback: series.length),
      totalElements:
          _parseIntOr(envelope['totalElements'], fallback: series.length),
      totalPages:
          _parseIntOr(envelope['totalPages'], fallback: series.isEmpty ? 0 : 1),
    );
  }

  /// `GET /tasks/board` (§6) → the three-column [TaskBoard].
  static TaskBoard board(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : null;
    final columns = data is Map<String, dynamic> ? data['columns'] : null;
    if (columns is! Map) return const TaskBoard.empty();
    TaskBoardColumn col(String key) => _column(columns[key]);
    return TaskBoard(
      toDo: col('TO_DO'),
      inProgress: col('IN_PROGRESS'),
      completed: col('COMPLETED'),
    );
  }

  static TaskBoardColumn _column(dynamic raw) {
    if (raw is! Map) return const TaskBoardColumn.empty();
    final items = raw['items'];
    final cards = <Task>[];
    if (items is List) {
      final seen = <String>{};
      for (final entry in items) {
        if (entry is! Map) continue;
        final model = TaskAssignmentModel.fromJson(
          entry.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (model.code.isEmpty || !seen.add(model.code)) continue;
        cards.add(model.toEntity());
      }
    }
    return TaskBoardColumn(
      cards: cards,
      page: _parseIntOr(raw['page']),
      size: _parseIntOr(raw['size'], fallback: cards.length),
      totalElements: _parseIntOr(raw['totalElements'], fallback: cards.length),
      totalPages: _parseIntOr(raw['totalPages'], fallback: cards.isEmpty ? 0 : 1),
    );
  }

  /// `POST /tasks/upload-session` (§8) → the opened session. Falls back to the
  /// provided default document base path when the server omits it.
  static TaskUploadSession uploadSession(
    dynamic raw, {
    required String fallbackDocumentBasePath,
  }) {
    final data = raw is Map<String, dynamic> ? raw['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected task upload-session response format');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Task upload session code is missing');
    }
    final basePath = (data['documentApiBasePath'] ?? '').toString().trim();
    return TaskUploadSession(
      sessionCode: sessionCode,
      documentApiBasePath:
          basePath.isEmpty ? fallbackDocumentBasePath : basePath,
    );
  }
}
