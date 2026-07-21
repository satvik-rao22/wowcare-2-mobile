import '../entities/task.dart';
import '../entities/task_assignee.dart';
import '../repositories/task_repository.dart';

/// Edits a single assignment by its own code (Tasks API §5b
/// `PATCH /tasks/assignments/{code}`). Accepts the full create-time field set —
/// every field optional (null = unchanged) — so the edit form can route its
/// entire save through this one endpoint.
class UpdateTaskAssignmentUseCase {
  UpdateTaskAssignmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call({
    required String assignmentCode,
    String? title,
    String? description,
    DateTime? dueAt,
    TaskPriority? priority,
    TaskStatus? status,
    double? effort,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
  }) {
    return _repository.updateAssignment(
      assignmentCode: assignmentCode,
      title: title,
      description: description,
      dueAt: dueAt,
      priority: priority,
      status: status,
      effort: effort,
      schedule: schedule,
      assignees: assignees,
      assetCodes: assetCodes,
    );
  }
}
