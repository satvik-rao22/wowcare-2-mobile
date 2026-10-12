import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/event_repository.dart';

class DeleteHolidayUseCase {
  DeleteHolidayUseCase(this._repository);

  final EventRepository _repository;

  Future<String> call(String code) {
    return AppEvents.track(
      AppEvent.eventHolidayDelete,
      () => _repository.deleteHoliday(code),
    );
  }
}
