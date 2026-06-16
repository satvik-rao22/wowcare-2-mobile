import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call() {
    return _repository.getTasks();
  }
}
