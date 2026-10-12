import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String code) {
    return AppEvents.track(
      AppEvent.taskDelete,
      () => _repository.deleteTask(code),
    );
  }
}
