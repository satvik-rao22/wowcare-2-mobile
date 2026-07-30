import '../entities/task_series.dart';
import '../repositories/task_repository.dart';

/// Full detail for one task series (Tasks API §2a `GET /tasks/{code}`),
/// including the recurrence breakdown the flat assignment cards omit.
class GetTaskUseCase {
  GetTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskSeries> call(String seriesCode) {
    return _repository.getTask(seriesCode);
  }
}
