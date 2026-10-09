import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/task_repository.dart';

/// Removes one assignee from a task's roster (Tasks API §4a) without touching
/// the series or any other assignee.
class RemoveTaskAssigneeUseCase {
  RemoveTaskAssigneeUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call({
    required String seriesCode,
    required String staffCode,
  }) {
    return AppEvents.track(
      AppEvent.taskUnassign,
      () => _repository.removeAssignee(
        seriesCode: seriesCode,
        staffCode: staffCode,
      ),
    );
  }
}
