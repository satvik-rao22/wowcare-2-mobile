import '../entities/task.dart';
import '../entities/task_assignee.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call({
    required Task draft,
    required List<TaskAssignee> assignees,
  }) {
    return _repository.createTask(draft: draft, assignees: assignees);
  }
}
