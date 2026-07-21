import '../entities/task_occurrence.dart';
import '../repositories/task_repository.dart';

/// Every occurrence of one series, ascending (Tasks API §11a). The only source
/// of occurrence codes for the occurrence-scoped edits.
class GetTaskOccurrencesUseCase {
  GetTaskOccurrencesUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<TaskOccurrence>> call(String seriesCode) {
    return _repository.getOccurrences(seriesCode);
  }
}
