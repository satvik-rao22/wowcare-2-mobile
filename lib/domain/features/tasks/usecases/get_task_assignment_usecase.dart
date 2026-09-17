import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// One assignment fetched by its own code (Tasks API §5a
/// `GET /tasks/assignments/{code}`).
class GetTaskAssignmentUseCase {
  GetTaskAssignmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(String assignmentCode) {
    return _repository.getAssignment(assignmentCode);
  }
}
