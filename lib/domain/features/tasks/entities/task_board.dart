import 'package:equatable/equatable.dart';

import 'task.dart';

/// One independently-paginated column of the Kanban board (Tasks API §6). Cards
/// are [Task] assignments; [totalElements]/[totalPages] describe that column's
/// own pagination, driven by the shared `page`/`size` on the request.
class TaskBoardColumn extends Equatable {
  const TaskBoardColumn({
    required this.cards,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  const TaskBoardColumn.empty()
      : cards = const [],
        page = 0,
        size = 0,
        totalElements = 0,
        totalPages = 0;

  final List<Task> cards;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  @override
  List<Object?> get props => [cards, page, size, totalElements, totalPages];
}

/// The Kanban board (Tasks API §6 `GET /tasks/board`): one column per status,
/// each independently paginated.
class TaskBoard extends Equatable {
  const TaskBoard({
    required this.toDo,
    required this.inProgress,
    required this.completed,
  });

  const TaskBoard.empty()
      : toDo = const TaskBoardColumn.empty(),
        inProgress = const TaskBoardColumn.empty(),
        completed = const TaskBoardColumn.empty();

  final TaskBoardColumn toDo;
  final TaskBoardColumn inProgress;
  final TaskBoardColumn completed;

  /// The column for [status].
  TaskBoardColumn column(TaskStatus status) {
    switch (status) {
      case TaskStatus.toDo:
        return toDo;
      case TaskStatus.inProgress:
        return inProgress;
      case TaskStatus.completed:
        return completed;
    }
  }

  @override
  List<Object?> get props => [toDo, inProgress, completed];
}
