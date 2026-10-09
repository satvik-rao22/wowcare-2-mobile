import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/event_repository.dart';

class UpdateOccurrenceUseCase {
  UpdateOccurrenceUseCase(this._repository);

  final EventRepository _repository;

  /// Overrides a single occurrence (scope THIS_ONLY): name, location,
  /// date and times. The series stays untouched.
  Future<void> call({
    required String eventCode,
    required String occurrenceCode,
    String? overrideName,
    String? overrideDescription,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  }) {
    return AppEvents.track(
      AppEvent.eventOccurrenceUpdate,
      () => _repository.updateOccurrence(
        eventCode: eventCode,
        occurrenceCode: occurrenceCode,
        overrideName: overrideName,
        overrideDescription: overrideDescription,
        scheduledStartDate: scheduledStartDate,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
      ),
    );
  }
}
