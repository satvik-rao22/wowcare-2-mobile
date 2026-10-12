import 'package:wowcare/core/observability/app_events.dart';

import '../entities/holiday.dart';
import '../repositories/event_repository.dart';

/// Creates a new school holiday (`POST /api/v1/holidays`).
class CreateHolidayUseCase {
  CreateHolidayUseCase(this._repository);

  final EventRepository _repository;

  Future<(Holiday, String)> call({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) {
    return AppEvents.track(
      AppEvent.eventHolidayCreate,
      () => _repository.createHoliday(
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
      ),
    );
  }
}

/// Updates an existing school holiday (`PATCH /api/v1/holidays/{code}`).
class UpdateHolidayUseCase {
  UpdateHolidayUseCase(this._repository);

  final EventRepository _repository;

  Future<(Holiday, String)> call({
    required String code,
    required int version,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) {
    return AppEvents.track(
      AppEvent.eventHolidayUpdate,
      () => _repository.updateHoliday(
        code: code,
        version: version,
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
      ),
    );
  }
}
