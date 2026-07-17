import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';

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
    final due = _parseDate(json['dueAt']) ?? occurrence;
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
    this.seriesStatus = 'ACTIVE',
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
      seriesStatus: (json['seriesStatus'] ?? 'ACTIVE').toString(),
      assigneeCount: parseInt(json['assigneeCount']),
      version: parseInt(json['version']),
    );
  }

  final String code;
  final String title;
  final String description;
  final bool recurringFlag;
  final String seriesStatus;
  final int assigneeCount;
  final int version;

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
    List<String> assetCodes = const [],
  }) {
    final body = <String, dynamic>{
      'title': draft.title,
      if (draft.description.isNotEmpty) 'description': draft.description,
      'priority': draft.priority.value,
      'effort': draft.effort,
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
  }) {
    return <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (holidayPolicy != null) 'holidayPolicy': holidayPolicy.value,
      if (schedule != null) ..._scheduleJson(schedule),
      if (assignees != null)
        'assignees': assignees.map(_assigneeJson).toList(),
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
