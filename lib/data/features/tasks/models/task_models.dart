import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/entities/task_upload_session.dart';

/// DTO for a single **task assignment** — one person's card on one occurrence
/// (Tasks API §5–§7). This is the unit the board, the flat assignments list
/// and the status endpoint all return, and it maps 1:1 onto a UI [Task] card.
///
/// The occurrence's schedule now arrives as discrete fields — [occurrenceDate]
/// (the card's own start day), [startTime], [dueDate] and [dueTime] — rather
/// than a single combined `dueAt` instant. The payload also carries
/// [description] (joined back from the parent series) and [effort], so a
/// card/detail screen no longer needs a separate series fetch to show them.
/// Recurrence and creator still live only on [TaskSeriesModel].
class TaskAssignmentModel extends Equatable {
  const TaskAssignmentModel({
    required this.code,
    required this.taskCode,
    required this.title,
    this.description = '',
    this.assigneeCode = '',
    this.assigneeName = '',
    this.createdBy = '',
    this.createdByName = '',
    required this.occurrenceDate,
    this.startTime = '',
    required this.dueDate,
    this.dueTime = '',
    this.priority = 'MEDIUM',
    this.status = 'TO_DO',
    this.effort = 0,
  });

  factory TaskAssignmentModel.fromJson(Map<String, dynamic> json) {
    final occurrence = _parseDate(json['occurrenceDate']) ?? DateTime.now();
    // Due date/time are now separate fields (Tasks API §5–§7); the older
    // combined `dueAt` instant is gone. `dueTime`/`startTime` arrive as
    // `HH:mm:ss` (or `HH:mm`) wall-clock strings — normalized to `HH:mm` — and
    // the due date falls back to the occurrence day when the payload omits it.
    return TaskAssignmentModel(
      code: (json['code'] ?? '').toString().trim(),
      taskCode: (json['taskCode'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString(),
      // Joined back from the parent series (§5a/§6/§7) — present on the card
      // payload now, so the detail screen reads it without a series fetch.
      description: (json['description'] ?? '').toString(),
      assigneeCode: (json['assigneeCode'] ?? '').toString().trim(),
      // Not part of the documented assignment payload; parsed opportunistically
      // so cards show a name if the backend ever denormalizes one.
      assigneeName: (json['assigneeName'] ?? '').toString(),
      // Who raised the task. Also undocumented in the §5a/§6/§7 item shape, but
      // the staff "By Me" scope and the "Created By" filter are built entirely
      // on it, so both spellings the service might use are accepted. Absent →
      // empty, which reads as "unknown author" rather than the current user.
      createdBy: _firstNonBlank(json, const [
        'createdBy',
        'createdByCode',
        'assignedBy',
        'assignedByCode',
      ]),
      createdByName: _firstNonBlank(json, const [
        'createdByName',
        'assignedByName',
      ]),
      occurrenceDate: occurrence,
      startTime: _hhmm(json['startTime']),
      dueDate: _parseDate(json['dueDate']) ?? occurrence,
      dueTime: _hhmm(json['dueTime']),
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      status: (json['status'] ?? 'TO_DO').toString(),
      // Estimated hours — per-assignment (the series has no `effort` field).
      effort: (json['effort'] is num)
          ? (json['effort'] as num).toDouble()
          : double.tryParse((json['effort'] ?? '').toString()) ?? 0,
    );
  }

  final String code;
  final String taskCode;
  final String title;
  final String description;
  final String assigneeCode;
  final String assigneeName;

  /// Staff code of whoever raised the task, and their display name when the
  /// payload denormalizes one. Empty when the service doesn't send a creator.
  final String createdBy;
  final String createdByName;

  final DateTime occurrenceDate;

  /// The occurrence's own start/due wall-clock times as `HH:mm` (empty when the
  /// payload omits them, so [toEntity] falls back to the entity defaults).
  final String startTime;
  final DateTime dueDate;
  final String dueTime;
  final String priority;
  final String status;
  final double effort;

  /// First of [keys] present on [json] with a non-blank value, trimmed; empty
  /// when none match. Lets one field tolerate several server-side spellings
  /// without the call site branching on each.
  static String _firstNonBlank(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = (json[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Task toEntity() {
    return Task(
      code: code,
      taskCode: taskCode,
      title: title,
      description: description,
      assigneeCode: assigneeCode,
      assigneeName: assigneeName,
      createdBy: createdBy,
      createdByName: createdByName,
      status: TaskStatus.fromValue(status),
      priority: TaskPriority.fromValue(priority),
      startDate: occurrenceDate,
      startTime: startTime.isEmpty ? '09:00' : startTime,
      dueDate: dueDate,
      dueTime: dueTime.isEmpty ? '17:00' : dueTime,
      effort: effort,
      createdAt: occurrenceDate,
      updatedAt: occurrenceDate,
    );
  }

  @override
  List<Object?> get props => [
        code,
        taskCode,
        title,
        description,
        assigneeCode,
        createdBy,
        occurrenceDate,
        startTime,
        dueDate,
        dueTime,
        priority,
        status,
        effort,
      ];
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
    this.rruleInterval,
    this.rruleByDay = const [],
    this.rruleByMonthday,
    this.rruleUntil,
    this.seriesStartDate,
    this.seriesStartTime = '',
    this.seriesEndTime = '',
    this.dueDate,
    this.holidayPolicy,
    this.seriesStatus = 'ACTIVE',
    this.nextOccurrenceDate,
    this.nextOccurrenceStatus = '',
    this.parentTaskCode,
    this.assigneeCount = 0,
    this.version = 0,
  });

  factory TaskSeriesModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic raw) {
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    int? parseNullableInt(dynamic raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString().trim());
    }

    String? emptyToNull(dynamic raw) {
      final value = (raw ?? '').toString().trim();
      return value.isEmpty ? null : value;
    }

    // Create/update/detail (§1/§2a/§3) return the recurrence as ONE RFC 5545
    // `rrule` string (e.g. `FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;UNTIL=20260930`)
    // plus a convenience `rruleUntil` parsed date — there are no separate
    // `rruleInterval`/`rruleByDay`/`rruleByMonthday` keys on the wire. The lean
    // series list (§2) instead sends a bare `rruleFreq` (just the FREQ token,
    // e.g. `"WEEKLY"`) with nothing else. Parse `rrule` when present and fall
    // back to the decomposed fields otherwise, so both shapes round-trip.
    final rrule = _RruleParts.parse(json['rrule']?.toString());
    return TaskSeriesModel(
      code: (json['code'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      recurringFlag: json['recurringFlag'] == true,
      rruleFreq: rrule?.freq ?? emptyToNull(json['rruleFreq']),
      rruleInterval: rrule?.interval ?? parseNullableInt(json['rruleInterval']),
      // Detail (§2a) returns `rruleByDay` comma-joined (`"MO,WE,FR"`); create
      // requests send a list. Accept either so this model round-trips both.
      rruleByDay:
          rrule != null && rrule.byDay.isNotEmpty
              ? rrule.byDay
              : _parseByDay(json['rruleByDay']),
      rruleByMonthday: rrule?.byMonthday ?? parseNullableInt(json['rruleByMonthday']),
      rruleUntil: rrule?.until ?? _parseDate(json['rruleUntil']),
      seriesStartDate: _parseDate(json['seriesStartDate']),
      seriesStartTime: (json['seriesStartTime'] ?? '').toString().trim(),
      seriesEndTime: (json['seriesEndTime'] ?? '').toString().trim(),
      dueDate: _parseDate(json['dueDate']),
      holidayPolicy: emptyToNull(json['holidayPolicy']),
      seriesStatus: (json['seriesStatus'] ?? 'ACTIVE').toString(),
      nextOccurrenceDate: _parseDate(json['nextOccurrenceDate']),
      nextOccurrenceStatus: (json['nextOccurrenceStatus'] ?? '').toString(),
      parentTaskCode: emptyToNull(json['parentTaskCode']),
      assigneeCount: parseInt(json['assigneeCount']),
      version: parseInt(json['version']),
    );
  }

  final String code;
  final String title;
  final String description;
  final bool recurringFlag;
  final String? rruleFreq;
  final int? rruleInterval;
  final List<String> rruleByDay;
  final int? rruleByMonthday;
  final DateTime? rruleUntil;
  final DateTime? seriesStartDate;
  final String seriesStartTime;
  final String seriesEndTime;
  final DateTime? dueDate;
  final String? holidayPolicy;
  final String seriesStatus;
  final DateTime? nextOccurrenceDate;
  final String nextOccurrenceStatus;
  final String? parentTaskCode;
  final int assigneeCount;
  final int version;

  /// Maps the DTO to its domain [TaskSeries] (Tasks API §2 list / §2a detail).
  TaskSeries toSeries() => TaskSeries(
        code: code,
        title: title,
        description: description,
        recurring: recurringFlag,
        recurrencePattern: TaskRecurrence.fromValue(rruleFreq),
        recurrenceInterval: rruleInterval,
        recurrenceByDay: rruleByDay,
        recurrenceByMonthday: rruleByMonthday,
        recurrenceUntil: rruleUntil,
        seriesStartDate: seriesStartDate,
        seriesStartTime: seriesStartTime,
        seriesEndTime: seriesEndTime,
        dueDate: dueDate,
        holidayPolicy:
            holidayPolicy == null ? null : TaskHolidayPolicy.fromValue(holidayPolicy),
        seriesStatus: TaskSeriesStatus.fromValue(seriesStatus),
        nextOccurrenceDate: nextOccurrenceDate,
        nextOccurrenceStatus: nextOccurrenceStatus,
        parentTaskCode: parentTaskCode,
        version: version,
      );

  static List<String> _parseByDay(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return raw
        .toString()
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [code, title, seriesStatus, assigneeCount, version];
}

/// DTO for a single **task occurrence** (Tasks API §11). Carries the
/// occurrence's identity ([originalStartDate]), its reschedulable window, any
/// per-occurrence overrides, and its assignment roll-up counts.
class TaskOccurrenceModel extends Equatable {
  const TaskOccurrenceModel({
    required this.code,
    required this.taskCode,
    this.sequenceNumber = 0,
    required this.originalStartDate,
    this.scheduledStartDate,
    this.scheduledStartTime = '',
    this.scheduledEndTime = '',
    this.overrideTitle,
    this.overrideDescription,
    this.isModified = false,
    this.status = 'SCHEDULED',
    this.statusReason,
    this.assignmentTotal = 0,
    this.assignmentInProgress = 0,
    this.assignmentCompleted = 0,
    this.version = 0,
  });

  factory TaskOccurrenceModel.fromJson(Map<String, dynamic> json) {
    String? emptyToNull(dynamic raw) {
      if (raw == null) return null;
      final value = raw.toString();
      return value.isEmpty ? null : value;
    }

    return TaskOccurrenceModel(
      code: (json['code'] ?? '').toString().trim(),
      taskCode: (json['taskCode'] ?? '').toString().trim(),
      sequenceNumber: _parseIntOr(json['sequenceNumber']),
      originalStartDate:
          _parseDate(json['originalStartDate']) ?? DateTime.now(),
      scheduledStartDate: _parseDate(json['scheduledStartDate']),
      scheduledStartTime: (json['scheduledStartTime'] ?? '').toString().trim(),
      scheduledEndTime: (json['scheduledEndTime'] ?? '').toString().trim(),
      overrideTitle: emptyToNull(json['overrideTitle']),
      overrideDescription: emptyToNull(json['overrideDescription']),
      isModified: json['isModified'] == true,
      status: (json['status'] ?? 'SCHEDULED').toString(),
      statusReason: emptyToNull(json['statusReason']),
      assignmentTotal: _parseIntOr(json['assignmentTotal']),
      assignmentInProgress: _parseIntOr(json['assignmentInProgress']),
      assignmentCompleted: _parseIntOr(json['assignmentCompleted']),
      version: _parseIntOr(json['version']),
    );
  }

  final String code;
  final String taskCode;
  final int sequenceNumber;
  final DateTime originalStartDate;
  final DateTime? scheduledStartDate;
  final String scheduledStartTime;
  final String scheduledEndTime;
  final String? overrideTitle;
  final String? overrideDescription;
  final bool isModified;
  final String status;
  final String? statusReason;
  final int assignmentTotal;
  final int assignmentInProgress;
  final int assignmentCompleted;
  final int version;

  TaskOccurrence toEntity() => TaskOccurrence(
        code: code,
        taskCode: taskCode,
        sequenceNumber: sequenceNumber,
        originalStartDate: originalStartDate,
        scheduledStartDate: scheduledStartDate,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        overrideTitle: overrideTitle,
        overrideDescription: overrideDescription,
        isModified: isModified,
        status: TaskOccurrenceStatus.fromValue(status),
        statusReason: statusReason,
        assignmentTotal: assignmentTotal,
        assignmentInProgress: assignmentInProgress,
        assignmentCompleted: assignmentCompleted,
        version: version,
      );

  @override
  List<Object?> get props =>
      [code, taskCode, originalStartDate, scheduledStartDate, status, version];
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
      // The API wants ONE RFC 5545 `rrule` string, not decomposed
      // freq/interval/byDay/byMonthday/until fields — those aren't a
      // recognized request shape and the server reports "rrule is required"
      // when they're sent instead.
      json['rrule'] = _buildRrule(task);
    } else {
      json['startDate'] = formatDate(task.startDate);
      json['dueDate'] = formatDate(task.dueDate);
    }
    return json;
  }

  /// Builds the single RFC 5545 `rrule` string the API requires when
  /// `recurring = true` (e.g. `FREQ=WEEKLY;INTERVAL=1;BYDAY=MO;UNTIL=20260930`).
  /// `INTERVAL=1` is always sent explicitly (the UI only models every-1
  /// cadence); `BYDAY`/`BYMONTHDAY` are included only for the matching
  /// frequency; `UNTIL` (basic `yyyyMMdd` format) is appended whenever an end
  /// date is set — the API validation notes call `UNTIL` mandatory, so a null
  /// [Task.recurringEndDate] here surfaces as a clear server-side 400 rather
  /// than the request silently omitting the whole `rrule` field.
  static String _buildRrule(Task task) {
    final freq = task.recurringPattern ?? TaskRecurrence.daily;
    final parts = <String>['FREQ=${freq.value}', 'INTERVAL=1'];
    if (freq == TaskRecurrence.weekly && task.startDay != null) {
      parts.add('BYDAY=${_weekdayAbbr(task.startDay!)}');
    }
    if (freq == TaskRecurrence.monthly && task.startDay != null) {
      final day = int.tryParse(task.startDay!.trim());
      if (day != null) parts.add('BYMONTHDAY=$day');
    }
    if (task.recurringEndDate != null) {
      parts.add('UNTIL=${_formatBasicDate(task.recurringEndDate!)}');
    }
    return parts.join(';');
  }

  /// `yyyyMMdd` — the basic date format RRULE's `UNTIL` requires (no dashes),
  /// distinct from [formatDate]'s `yyyy-MM-dd`.
  static String _formatBasicDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  /// Body for `PATCH /api/v1/tasks/assignments/{code}/status`.
  static Map<String, dynamic> statusBody(TaskStatus status) =>
      <String, dynamic>{'status': status.value};

  /// Body for `PATCH /api/v1/tasks/{code}/assignees/{staffCode}` (§4b) — a
  /// single assignee's priority in isolation. `priority` is required.
  static Map<String, dynamic> assigneePriorityBody(TaskPriority priority) =>
      <String, dynamic>{'priority': priority.value};

  /// Body for `PATCH /api/v1/tasks/assignments/{code}` (§5b). Every field is
  /// optional — an omitted/null field means "leave unchanged" — so callers send
  /// only what changed. The occurrence's own schedule now travels as the
  /// discrete [occurrenceDate]/[startTime]/[dueDate]/[dueTime] the endpoint
  /// documents (no combined `dueAt` instant). Beyond those, the endpoint also
  /// accepts the rest of the create-time field set ([title], [description],
  /// [priority], [status], [effort], the [schedule] recurrence rule for a
  /// recurring series, roster [assignees] and [assetCodes]); the app funnels
  /// every edit-form save through here rather than the series endpoint. Dates
  /// serialize as `YYYY-MM-DD`; [startTime]/[dueTime] are `HH:mm` wall-clock.
  static Map<String, dynamic> assignmentPatchBody({
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
  }) =>
      <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (occurrenceDate != null) 'occurrenceDate': formatDate(occurrenceDate),
        if (startTime != null) 'startTime': startTime,
        if (dueDate != null) 'dueDate': formatDate(dueDate),
        if (dueTime != null) 'dueTime': dueTime,
        if (priority != null) 'priority': priority.value,
        if (status != null) 'status': status.value,
        if (effort != null) 'effort': effort,
        if (schedule != null) ..._scheduleJson(schedule),
        if (assignees != null) 'assignees': assignees.map(_assigneeJson).toList(),
        if (assetCodes != null) 'assetCodes': assetCodes,
      };

  /// Body for `PATCH /api/v1/tasks/{code}/occurrences/{occurrenceCode}`
  /// (§11c, THIS_ONLY). Every field optional; omitted means unchanged.
  static Map<String, dynamic> occurrencePatchBody({
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) =>
      <String, dynamic>{
        if (scheduledStartDate != null)
          'scheduledStartDate': formatDate(scheduledStartDate),
        if (scheduledStartTime != null)
          'scheduledStartTime': scheduledStartTime,
        if (scheduledEndTime != null) 'scheduledEndTime': scheduledEndTime,
        // Checked against null (not emptiness) so an explicit `""` clears an
        // override rather than being dropped.
        if (overrideTitle != null) 'overrideTitle': overrideTitle,
        if (overrideDescription != null)
          'overrideDescription': overrideDescription,
      };

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

/// Parsed pieces of an RFC 5545 `rrule` string (e.g.
/// `FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;UNTIL=20260930`), as returned by the
/// create/update/detail (§1/§2a/§3) response's `rrule` field. [parse] returns
/// `null` for a blank/absent string so callers fall back to whatever
/// decomposed fields the payload carries instead (the lean §2 list shape,
/// which sends a bare `rruleFreq` and nothing else).
class _RruleParts {
  const _RruleParts({
    this.freq,
    this.interval,
    this.byDay = const [],
    this.byMonthday,
    this.until,
  });

  final String? freq;
  final int? interval;
  final List<String> byDay;
  final int? byMonthday;
  final DateTime? until;

  static _RruleParts? parse(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    String? freq;
    int? interval;
    var byDay = const <String>[];
    int? byMonthday;
    DateTime? until;

    for (final segment in value.split(';')) {
      final eq = segment.indexOf('=');
      if (eq <= 0) continue;
      final key = segment.substring(0, eq).trim().toUpperCase();
      final val = segment.substring(eq + 1).trim();
      if (key == 'FREQ') {
        freq = val.toUpperCase();
      } else if (key == 'INTERVAL') {
        interval = int.tryParse(val);
      } else if (key == 'BYDAY') {
        byDay = val
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (key == 'BYMONTHDAY') {
        byMonthday = int.tryParse(val.split(',').first.trim());
      } else if (key == 'UNTIL') {
        until = _parseBasicDate(val);
      }
    }

    return _RruleParts(
      freq: freq,
      interval: interval,
      byDay: byDay,
      byMonthday: byMonthday,
      until: until,
    );
  }

  /// `yyyyMMdd` (RRULE's basic date format for `UNTIL`) → [DateTime]. Returns
  /// null for anything malformed rather than guessing.
  static DateTime? _parseBasicDate(String raw) {
    final digits = raw.trim();
    if (digits.length < 8) return null;
    final year = int.tryParse(digits.substring(0, 4));
    final month = int.tryParse(digits.substring(4, 6));
    final day = int.tryParse(digits.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}

/// Normalizes a wire time (`HH:mm:ss` or `HH:mm`) to the `HH:mm` the entity and
/// UI expect. Returns `''` when the value is absent or malformed, so [toEntity]
/// can fall back to the entity's own default.
String _hhmm(dynamic raw) {
  final value = (raw ?? '').toString().trim();
  if (value.isEmpty) return '';
  final parts = value.split(':');
  if (parts.length < 2) return '';
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return '';
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

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

  /// `GET /tasks/{code}/occurrences` (§11a) → the ascending occurrence list.
  /// `data` is a bare array here (not an `items` envelope). Tolerant of a
  /// malformed payload — degrades to an empty list.
  static List<TaskOccurrence> occurrenceList(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (data is! List) return const <TaskOccurrence>[];
    final result = <TaskOccurrence>[];
    for (final entry in data) {
      if (entry is! Map) continue;
      final model = TaskOccurrenceModel.fromJson(
        entry.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (model.code.isNotEmpty) result.add(model.toEntity());
    }
    return result;
  }

  /// `GET`/`PATCH`/`DELETE` on one occurrence (§11b–d) → the single occurrence.
  static TaskOccurrence occurrence(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected task occurrence response format');
    }
    return TaskOccurrenceModel.fromJson(data).toEntity();
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

  /// `GET /tasks/{code}/attachments` → the attachment rows.
  ///
  /// The Tasks samples don't document this endpoint (only the write-side
  /// `assetCodes`), so the shape is taken from the equivalent events one and
  /// parsed liberally: `data` may be a bare array or an `{items: []}` envelope,
  /// and each row may carry the asset fields inline or nested under
  /// `asset`/`mediaAsset`. Anything unparseable degrades to an empty list
  /// rather than breaking the screen.
  static List<TaskAttachment> attachmentList(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : raw;
    final items = data is Map ? (data['items'] ?? data['attachments']) : data;
    if (items is! List) return const <TaskAttachment>[];

    final result = <TaskAttachment>[];
    for (final entry in items) {
      if (entry is! Map) continue;
      final row = entry.map((k, v) => MapEntry(k.toString(), v));
      final attachment = _attachment(row);
      if (attachment.assetCode.isNotEmpty || attachment.code.isNotEmpty) {
        result.add(attachment);
      }
    }
    return result;
  }

  static TaskAttachment _attachment(Map<String, dynamic> row) {
    // Asset metadata sits inline on some payloads and nested on others.
    final nested = row['asset'] ?? row['mediaAsset'] ?? row['document'];
    final asset = nested is Map
        ? nested.map((k, v) => MapEntry(k.toString(), v))
        : const <String, dynamic>{};

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = (row[key] ?? asset[key] ?? '').toString().trim();
        if (value.isNotEmpty && value != 'null') return value;
      }
      return '';
    }

    final size = row['sizeBytes'] ??
        row['contentLengthBytes'] ??
        asset['sizeBytes'] ??
        asset['contentLengthBytes'];

    return TaskAttachment(
      // `code` on a nested payload belongs to the attachment row; on a flat one
      // it can be either, so `attachmentCode` is preferred when present.
      code: pick(['attachmentCode', 'code']),
      assetCode: pick(['assetCode', 'documentAssetCode']),
      fileName: pick(['fileName', 'name', 'originalFileName']),
      contentType: pick(['contentType', 'mimeType']),
      sizeBytes: size is num ? size.toInt() : int.tryParse('$size') ?? 0,
      mediaType: pick(['mediaType', 'type']),
      status: pick(['status', 'assetStatus']),
      url: pick(['deliveryUrl', 'artifactUrl', 'url', 'originalDownloadUrl']),
      thumbnailUrl: pick(['thumbnailUrl']),
    );
  }
}
