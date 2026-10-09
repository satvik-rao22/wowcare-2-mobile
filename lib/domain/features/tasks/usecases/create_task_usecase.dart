import 'package:wowcare/core/observability/app_events.dart';

import '../entities/task.dart';
import '../entities/task_assignee.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  /// Returns the created series' `TSK_…` code.
  Future<String> call({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) {
    return AppEvents.track(
      AppEvent.taskCreate,
      () => _repository.createTask(
        draft: draft,
        assignees: assignees,
        holidayPolicy: holidayPolicy,
        assetCodes: assetCodes,
      ),
      count: assignees.length,
    );
  }
}
