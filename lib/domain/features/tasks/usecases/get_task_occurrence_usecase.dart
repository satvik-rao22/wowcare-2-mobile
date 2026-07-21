import '../entities/task_occurrence.dart';
import '../repositories/task_repository.dart';

/// One occurrence's own detail (Tasks API §11b).
class GetTaskOccurrenceUseCase {
  GetTaskOccurrenceUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskOccurrence> call({
    required String seriesCode,
    required String occurrenceCode,
  }) {
    return _repository.getOccurrence(
      seriesCode: seriesCode,
      occurrenceCode: occurrenceCode,
    );
  }
}
