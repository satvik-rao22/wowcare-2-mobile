import 'package:equatable/equatable.dart';

import 'task.dart';

/// Shared read-side filter for the assignment endpoints — the flat list
/// (Tasks API §7 `GET /tasks/assignments`) and the Kanban board
/// (§6 `GET /tasks/board`) accept exactly the same query parameters.
///
/// Every field is optional; an empty collection / null means "don't filter on
/// this". [statuses] narrows the flat list but is ignored by the board (which
/// always returns all three columns).
class TaskQuery extends Equatable {
  const TaskQuery({
    this.assigneeCodes = const <String>[],
    this.priorities = const <TaskPriority>[],
    this.statuses = const <TaskStatus>[],
    this.fromDate,
    this.toDate,
    this.overdue,
    this.query,
    this.page = 0,
    this.size = 20,
  });

  final List<String> assigneeCodes;
  final List<TaskPriority> priorities;
  final List<TaskStatus> statuses;

  /// Inclusive due-date window (`fromDate`/`toDate`), sent as `YYYY-MM-DD`.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// When set, restricts to overdue (`true`) or not-overdue (`false`) cards.
  final bool? overdue;

  /// Free-text search on title (`q`).
  final String? query;

  final int page;
  final int size;

  TaskQuery copyWith({int? page, int? size}) => TaskQuery(
        assigneeCodes: assigneeCodes,
        priorities: priorities,
        statuses: statuses,
        fromDate: fromDate,
        toDate: toDate,
        overdue: overdue,
        query: query,
        page: page ?? this.page,
        size: size ?? this.size,
      );

  @override
  List<Object?> get props => [
        assigneeCodes,
        priorities,
        statuses,
        fromDate,
        toDate,
        overdue,
        query,
        page,
        size,
      ];
}
