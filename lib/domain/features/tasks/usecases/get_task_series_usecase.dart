import '../entities/task_series.dart';
import '../repositories/task_repository.dart';

/// One page of the task-series list (Tasks API §2 `GET /tasks`).
class GetTaskSeriesUseCase {
  GetTaskSeriesUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskSeriesPage> call({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? query,
    int page = 0,
    int size = 20,
  }) {
    return _repository.getTaskSeries(
      seriesStatus: seriesStatus,
      recurring: recurring,
      query: query,
      page: page,
      size: size,
    );
  }
}
