import '../../../../domain/features/scheduling/repositories/staff_scheduling_repository.dart';
import '../../../../domain/features/staff/entities/staff_shift.dart';
import '../../staff/mappers/staff_shift_mapper.dart';
import '../datasources/staff_scheduling_remote_datasource.dart';

class StaffSchedulingRepositoryImpl implements StaffSchedulingRepository {
  StaffSchedulingRepositoryImpl(this._remoteDataSource);

  final StaffSchedulingRemoteDataSource _remoteDataSource;

  @override
  Future<StaffShiftDaySummary> getStaffShiftsForDay({
    required String organizationCode,
    required String schoolCode,
    required String staffCode,
    required DateTime date,
    String? classroomCode,
    List<String>? shiftStatus,
    Map<String, String> classroomNamesByCode = const {},
  }) async {
    final dateStr = StaffShiftMapper.formatApiDate(date);
    final page = await _remoteDataSource.getStaffShifts(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      staffCode: staffCode,
      dateFrom: dateStr,
      dateTo: dateStr,
      classroomCode: classroomCode,
      shiftStatus: shiftStatus,
    );
    return StaffShiftMapper.toDaySummary(
      page,
      classroomNamesByCode: classroomNamesByCode,
    );
  }
}
