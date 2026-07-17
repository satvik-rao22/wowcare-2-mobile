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
class TaskSeries extends Equatable {
  const TaskSeries({
    required this.code,
    required this.title,
    this.recurring = false,
    this.recurrencePattern,
    this.seriesStartDate,
    this.seriesStatus = TaskSeriesStatus.active,
    this.nextOccurrenceDate,
    this.nextOccurrenceStatus = '',
    this.version = 0,
  });

  final String code;
  final String title;
  final bool recurring;
  final TaskRecurrence? recurrencePattern;
  final DateTime? seriesStartDate;
  final TaskSeriesStatus seriesStatus;
  final DateTime? nextOccurrenceDate;
  final String nextOccurrenceStatus;
  final int version;

  @override
  List<Object?> get props => [
        code,
        title,
        recurring,
        recurrencePattern,
        seriesStartDate,
        seriesStatus,
        nextOccurrenceDate,
        nextOccurrenceStatus,
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
