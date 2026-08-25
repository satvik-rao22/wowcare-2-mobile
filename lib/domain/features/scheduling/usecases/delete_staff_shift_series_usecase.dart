import '../repositories/staff_shift_repository.dart';

/// `DELETE /api/v1/staff-shifts/series/{seriesCode}` — remove every shift in a
/// recurring series.
class DeleteStaffShiftSeriesUseCase {
  DeleteStaffShiftSeriesUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<void> call({required String seriesCode, String? staffCode}) {
    return _repository.deleteStaffShiftSeries(
      seriesCode: seriesCode,
      staffCode: staffCode,
    );
  }
}
