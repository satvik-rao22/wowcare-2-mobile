import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/task_repository.dart';

/// Removes one occurrence for one assignee — must be `TO_DO` (Tasks API §5c
/// `DELETE /tasks/assignments/{code}`). Distinct from removing the assignee
/// from the whole roster (§4a).
class DeleteTaskAssignmentUseCase {
  DeleteTaskAssignmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String assignmentCode) {
    return AppEvents.track(
      AppEvent.taskAssignmentDelete,
      () => _repository.deleteAssignment(assignmentCode),
    );
  }
}
