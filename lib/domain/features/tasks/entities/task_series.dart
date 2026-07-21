import 'package:equatable/equatable.dart';

import 'task.dart';

/// The status of a task series (Tasks API `TaskSeriesStatus`).
enum TaskSeriesStatus {
  active('ACTIVE'),
  paused('PAUSED'),
  ended('ENDED');

  const TaskSeriesStatus(this.value);

  final String value;

  static TaskSeriesStatus fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    return TaskSeriesStatus.values.firstWhere(
      (s) => s.value == normalized,
      orElse: () => TaskSeriesStatus.active,
    );
  }
}

/// One row of the task-series list (Tasks API §2 `GET /tasks`). A series is the
/// definition that owns a roster and materializes per-assignee assignments; the
/// list is one row per series, without occurrence/per-assignee status (use
/// §6/§7 for those).
///
/// The list endpoint (§2) only populates the lighter fields; the full-detail
/// fields ([description], the RRULE breakdown, series times, [dueDate],
/// [holidayPolicy], [parentTaskCode]) are filled in when fetched via
/// `GET /tasks/{code}` (§2a) — enough for the edit form to pre-populate an
/// existing series' recurrence, which the lean assignment cards can't do.
class TaskSeries extends Equatable {
  const TaskSeries({
    required this.code,
    required this.title,
    this.description = '',
    this.recurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceByDay = const [],
    this.recurrenceByMonthday,
    this.recurrenceUntil,
    this.seriesStartDate,
    this.seriesStartTime = '',
    this.seriesEndTime = '',
    this.dueDate,
    this.holidayPolicy,
    this.seriesStatus = TaskSeriesStatus.active,
    this.nextOccurrenceDate,
    this.nextOccurrenceStatus = '',
    this.parentTaskCode,
    this.version = 0,
  });

  final String code;
  final String title;
  final String description;
  final bool recurring;
  final TaskRecurrence? recurrencePattern;

  /// Every-N cadence (`rruleInterval`); null on the list endpoint.
  final int? recurrenceInterval;

  /// Weekly day abbreviations (e.g. `['MO', 'WE', 'FR']`) — detail-only.
  final List<String> recurrenceByDay;

  /// Monthly day-of-month (1–31) — detail-only.
  final int? recurrenceByMonthday;

  /// Series end date (`rruleUntil`) — detail-only.
  final DateTime? recurrenceUntil;

  final DateTime? seriesStartDate;
  final String seriesStartTime;
  final String seriesEndTime;

  /// One-off due date; null for a recurring series (each occurrence carries its
  /// own instead).
  final DateTime? dueDate;

  final TaskHolidayPolicy? holidayPolicy;
  final TaskSeriesStatus seriesStatus;
  final DateTime? nextOccurrenceDate;
  final String nextOccurrenceStatus;
  final String? parentTaskCode;
  final int version;

  @override
  List<Object?> get props => [
        code,
        title,
        description,
        recurring,
        recurrencePattern,
        recurrenceInterval,
        recurrenceByDay,
        recurrenceByMonthday,
        recurrenceUntil,
        seriesStartDate,
        seriesStartTime,
        seriesEndTime,
        dueDate,
        holidayPolicy,
        seriesStatus,
        nextOccurrenceDate,
        nextOccurrenceStatus,
        parentTaskCode,
        version,
      ];
}

/// A single page of task series (Tasks API §2 paginated envelope).
class TaskSeriesPage extends Equatable {
  const TaskSeriesPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<TaskSeries> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  @override
  List<Object?> get props => [items, page, size, totalElements, totalPages];
}
