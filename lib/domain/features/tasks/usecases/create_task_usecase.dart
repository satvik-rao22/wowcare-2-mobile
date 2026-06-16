import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(Task task) {
    return _repository.createTask(task);
  }
}
