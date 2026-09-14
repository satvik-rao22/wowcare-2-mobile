import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

import '../../core/config/av2_config.dart';
import '../../core/utils/av2_time_zone.dart';
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
    final profile = OverviewMapper.fromResponse(
      body,
      fallbackStaffCode: staffCode,
      fallbackStaffName: staffName,
      rangeStart: from,
      rangeEnd: to,
    );

    // The overview's absent days don't carry the absence record `code` (needed
    // to edit/delete). Backfill it (and details) from the absence list, which
    // does include it. Best-effort — never block the screen if it fails.
    final needsBackfill = profile.days.any((d) => d.isAbsent && !d.canEditAbsence);
    if (!needsBackfill) return profile;
    try {
      final absences = await _fetchAbsences(staffCode, from, to);
      if (absences.isEmpty) return profile;
      final enrichedDays = profile.days.map((d) {
        if (!d.isAbsent || d.canEditAbsence) return d;
        final a = _absenceForDate(absences, d.date);
        if (a == null) return d;
        return d.copyWith(
          absenceCode: a['code'] as String?,
          absenceReason: a['reason'] as String?,
          absenceType: a['type'] as String?,
          absenceFromDate: a['from'] as DateTime?,
          absenceToDate: a['to'] as DateTime?,
          absenceNote: a['note'] as String?,
          absenceMarkedByName: a['markedBy'] as String?,
        );
      }).toList();
      return profile.copyWith(days: enrichedDays);
    } catch (_) {
      return profile;
    }
  }

  /// Fetches absence records (which carry the `code`) for the range via the
  /// existing absent-toggle endpoint, returning lightweight maps.
  Future<List<Map<String, dynamic>>> _fetchAbsences(
    String staffCode,
    DateTime from,
    DateTime to,
  ) async {
    final body = await _attendanceSource.fetchStaffAttendanceProfileAbsentToggle(
      queryParameters: <String, dynamic>{
        'staffCode': staffCode,
        'fromAbsenceDate': _fmt(from),
        'toAbsenceDate': _fmt(to),
        'page': 0,
        'size': Av2Config.profilePageSize,
        'pageable.page': 0,
        'pageable.size': Av2Config.profilePageSize,
        'sort': <String>['absenceDate,desc'],
      },
    );
    final map = body ?? const <String, dynamic>{};
    final data = map['data'] as Map?;
    final records = data?['records'] as Map?;
    final content = (records?['content'] as List?) ?? const [];
    return content.whereType<Map>().map((e) {
      final m = e.cast<String, dynamic>();
      return <String, dynamic>{
        'code': (m['code'] ?? m['absenceCode'])?.toString(),
        'date': DateTime.tryParse((m['absenceDate'] ?? '').toString()),
        'from': DateTime.tryParse((m['absenceFromDate'] ?? '').toString()),
        'to': DateTime.tryParse((m['absenceToDate'] ?? '').toString()),
        'reason': m['absenceReason']?.toString(),
        'type': m['absenceType']?.toString(),
        'note': m['absenceNote']?.toString(),
        'markedBy': (m['markedAbsentByName'] ?? m['markedAbsentBy'])?.toString(),
      };
    }).where((m) => (m['code'] as String?)?.isNotEmpty ?? false).toList();
  }

  /// Matches an absent day to its absence record (by exact date, else by the
  /// record's from..to range).
  Map<String, dynamic>? _absenceForDate(
    List<Map<String, dynamic>> absences,
    DateTime date,
  ) {
    final d = DateTime(date.year, date.month, date.day);
    for (final a in absences) {
      final ad = a['date'] as DateTime?;
      if (ad != null &&
          ad.year == d.year &&
          ad.month == d.month &&
          ad.day == d.day) {
        return a;
      }
    }
    for (final a in absences) {
      final f = a['from'] as DateTime?;
      final t = a['to'] as DateTime?;
      if (f != null && t != null) {
        final fd = DateTime(f.year, f.month, f.day);
        final td = DateTime(t.year, t.month, t.day);
        if (!d.isBefore(fd) && !d.isAfter(td)) return a;
      }
    }
    return null;
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

  @override
  Future<void> editSession({
    required String recordCode,
    required String staffCode,
    required DateTime signInLocal,
    DateTime? signOutLocal,
    required String timeZone,
  }) {
    final zone = Av2TimeZone.resolveZone(timeZone);
    final body = <String, dynamic>{
      'staffCode': staffCode,
      'signedInAt': Av2TimeZone.toUtcIso(signInLocal, zone),
      'signedInMethod': Av2Config.editMethod,
      'timeZone': zone,
    };
    if (signOutLocal != null) {
      body['signedOutAt'] = Av2TimeZone.toUtcIso(signOutLocal, zone);
      body['signedOutMethod'] = Av2Config.editMethod;
    }
    return _overviewSource.editDailyRecord(recordCode: recordCode, body: body);
  }

  @override
  Future<void> deleteSession({
    required String recordCode,
    required String staffCode,
  }) {
    return _overviewSource.deleteDailyRecord(
      recordCode: recordCode,
      staffCode: staffCode,
    );
  }

  @override
  Future<void> editAbsence({
    required String code,
    required String staffCode,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String type,
    required String note,
  }) async {
    await _overviewSource.editAbsence(
      code: code,
      body: <String, dynamic>{
        'staffCode': staffCode,
        'absenceFromDate': _fmt(fromDate),
        'absenceToDate': _fmt(toDate),
        'absenceReason': reason,
        'absenceType': type,
        'absenceNote': note,
      },
    );
    // Best-effort shift sync — never fail the edit if it errors.
    try {
      final schoolCode =
          (await serviceLocator<StorageService>().getString(StorageKeys.schoolCode) ?? '')
              .trim();
      if (schoolCode.isNotEmpty) {
        await _overviewSource.markAbsentDays(
          staffCode: staffCode,
          absentDates: _dateRange(fromDate, toDate),
          schoolCode: schoolCode,
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteAbsence({
    required String code,
    required String staffCode,
  }) {
    return _overviewSource.deleteAbsence(code: code, staffCode: staffCode);
  }

  List<String> _dateRange(DateTime from, DateTime to) {
    final out = <String>[];
    var d = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!d.isAfter(end)) {
      out.add(_fmt(d));
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _two(int n) => n.toString().padLeft(2, '0');
}
