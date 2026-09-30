import '../entities/holiday.dart';
import '../repositories/event_repository.dart';

/// Approves/rejects/re-approves a federal holiday
/// (`PATCH /api/v1/holidays/{code}/status`).
class SetHolidayStatusUseCase {
  SetHolidayStatusUseCase(this._repository);

  final EventRepository _repository;

  Future<(Holiday, String)> call({
    required String code,
    required int version,
    required HolidayStatusAction action,
  }) {
    return _repository.setHolidayStatus(
      code: code,
      version: version,
      action: action,
    );
  }
}
