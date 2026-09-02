import '../entities/day_detail.dart';
import '../repositories/attendance_v2_repository.dart';

/// Loads sessions + breaks for one day (when a day row is expanded).
class GetDayDetailUseCase {
  GetDayDetailUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<DayDetail> call({
    required String staffCode,
    required DateTime date,
  }) {
    return _repository.getDayDetail(staffCode: staffCode, date: date);
  }
}
