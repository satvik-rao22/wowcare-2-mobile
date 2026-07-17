import '../entities/task.dart';
import '../entities/task_assignee.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
  }) {
    return _repository.updateTask(
      seriesCode: seriesCode,
      title: title,
      description: description,
      holidayPolicy: holidayPolicy,
      schedule: schedule,
      assignees: assignees,
    );
  }
}
