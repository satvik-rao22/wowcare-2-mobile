import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

/// `PUT /api/v1/staff-shifts/series/{seriesCode}` — update every shift in a
/// recurring series.
class UpdateStaffShiftSeriesUseCase {
  UpdateStaffShiftSeriesUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<StaffShiftCreateResult> call(StaffShiftSeriesUpdateRequest request) {
    return _repository.updateStaffShiftSeries(request);
  }
}
