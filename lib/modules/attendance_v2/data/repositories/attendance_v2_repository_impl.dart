import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

import '../../core/config/av2_config.dart';
import '../../domain/entities/day_detail.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../../domain/repositories/attendance_v2_repository.dart';
import '../datasources/staff_overtime_remote_datasource.dart';
import '../mappers/day_detail_mapper.dart';
import '../mappers/overview_mapper.dart';

/// Overview comes from the new overtime endpoint (own datasource, host Dio).
/// Day detail reuses the host's [AttendanceRepository] (existing
/// `/staff-attendance/profile` GET) for a single day — no new networking there.
class AttendanceV2RepositoryImpl implements AttendanceV2Repository {
  AttendanceV2RepositoryImpl(this._overviewSource, this._attendanceSource);

  final StaffOvertimeRemoteDataSource _overviewSource;
  final AttendanceRepository _attendanceSource;

  @override
  Future<void> calculate({
    required String staffCode,
    required DateTime from,
    required DateTime to,
  }) {
    return _overviewSource.calculate(
      staffCode: staffCode,
      fromDate: _fmt(from),
      toDate: _fmt(to),
    );
  }

  @override
  Future<StaffOvertimeProfile> getOverview({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) async {
    final body = await _overviewSource.getOverview(
      staffCode: staffCode,
      fromDate: _fmt(from),
      toDate: _fmt(to),
    );
    return OverviewMapper.fromResponse(
      body,
      fallbackStaffCode: staffCode,
      fallbackStaffName: staffName,
      rangeStart: from,
      rangeEnd: to,
    );
  }

  @override
  Future<DayDetail> getDayDetail({
    required String staffCode,
    required DateTime date,
  }) async {
    final day = _fmt(date);
    final body = await _attendanceSource.fetchStaffAttendanceProfile(
      queryParameters: <String, dynamic>{
        'staffCode': staffCode,
        'fromAttendanceDate': day,
        'toAttendanceDate': day,
        'page': 0,
        'size': Av2Config.profilePageSize,
      },
    );
    return DayDetailMapper.fromResponse(body, date);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _two(int n) => n.toString().padLeft(2, '0');
}
