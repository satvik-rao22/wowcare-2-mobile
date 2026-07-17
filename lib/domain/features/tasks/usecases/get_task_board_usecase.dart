import '../entities/task_board.dart';
import '../entities/task_query.dart';
import '../repositories/task_repository.dart';

/// The Kanban board grouped into status columns (Tasks API §6
/// `GET /tasks/board`), each column independently paginated by [query].
class GetTaskBoardUseCase {
  GetTaskBoardUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskBoard> call([TaskQuery query = const TaskQuery()]) {
    return _repository.getBoard(query);
  }
}
