import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

import '../../core/config/av2_config.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../../domain/repositories/attendance_v2_repository.dart';
import '../mappers/staff_overtime_mapper.dart';

/// Reuses the host app's [AttendanceRepository] (and therefore its Dio client,
/// auth + logging interceptors) to fetch the raw profile, then maps it into
/// module entities. No new networking is introduced.
class AttendanceV2RepositoryImpl implements AttendanceV2Repository {
  AttendanceV2RepositoryImpl(this._source);

  final AttendanceRepository _source;

  @override
  Future<StaffOvertimeProfile> getStaffProfile({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) async {
    final body = await _source.fetchStaffAttendanceProfile(
      queryParameters: <String, dynamic>{
        'staffCode': staffCode,
        'fromAttendanceDate': _fmt(from),
        'toAttendanceDate': _fmt(to),
        'page': 0,
        'size': Av2Config.profilePageSize,
        'sort': <String>['attendanceDate,desc'],
      },
    );

    return StaffOvertimeMapper.fromResponse(
      body,
      fallbackStaffCode: staffCode,
      fallbackStaffName: staffName,
      rangeStart: from,
      rangeEnd: to,
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  String _two(int n) => n.toString().padLeft(2, '0');
}
