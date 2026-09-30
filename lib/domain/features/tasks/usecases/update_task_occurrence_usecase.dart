import '../entities/task_occurrence.dart';
import '../repositories/task_repository.dart';

/// Reschedule/override one occurrence only — the series, other occurrences and
/// other assignees are untouched (Tasks API §11c, THIS_ONLY).
class UpdateTaskOccurrenceUseCase {
  UpdateTaskOccurrenceUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskOccurrence> call({
    required String seriesCode,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) {
    return _repository.updateOccurrence(
      seriesCode: seriesCode,
      occurrenceCode: occurrenceCode,
      scheduledStartDate: scheduledStartDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      overrideTitle: overrideTitle,
      overrideDescription: overrideDescription,
    );
  }
}
