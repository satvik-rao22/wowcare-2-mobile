import 'package:wowcare/core/observability/app_events.dart';

import '../entities/task_occurrence.dart';
import '../repositories/task_repository.dart';

/// Cancels one occurrence, keeping its row/history (Tasks API §11d) — unlike a
/// whole-series/roster delete. Returns the cancelled occurrence.
class CancelTaskOccurrenceUseCase {
  CancelTaskOccurrenceUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskOccurrence> call({
    required String seriesCode,
    required String occurrenceCode,
    String? reason,
  }) {
    return AppEvents.track(
      AppEvent.taskOccurrenceCancel,
      () => _repository.cancelOccurrence(
        seriesCode: seriesCode,
        occurrenceCode: occurrenceCode,
        reason: reason,
      ),
    );
  }
}
