import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Quick status change on a single task assignment — Kanban drag-and-drop and
/// the list view's inline status badge (Tasks API §5).
class UpdateTaskAssignmentStatusUseCase {
  UpdateTaskAssignmentStatusUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call({
    required String assignmentCode,
    required TaskStatus status,
  }) {
    return _repository.updateAssignmentStatus(
      assignmentCode: assignmentCode,
      status: status,
    );
  }
}
