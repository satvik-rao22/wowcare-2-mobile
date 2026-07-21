import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Updates one assignee's priority in isolation (Tasks API §4b), cascading it
/// onto their future assignments without resending the whole roster.
class UpdateTaskAssigneePriorityUseCase {
  UpdateTaskAssigneePriorityUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call({
    required String seriesCode,
    required String staffCode,
    required TaskPriority priority,
  }) {
    return _repository.updateAssigneePriority(
      seriesCode: seriesCode,
      staffCode: staffCode,
      priority: priority,
    );
  }
}
