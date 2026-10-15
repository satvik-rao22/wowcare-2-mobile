import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

import '../../core/config/av2_config.dart';
import '../../core/utils/av2_time_zone.dart';
import '../../domain/entities/av2_classroom.dart';
import '../../domain/entities/av2_staff_summary.dart';
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
    int page = 0,
    int size = Av2Config.overviewPageSize,
    bool overtimeOnly = false,
    bool absentOnly = false,
  }) async {
    final body = await _overviewSource.getOverview(
      staffCode: staffCode,
      fromDate: _fmt(from),
      toDate: _fmt(to),
      page: page,
      size: size,
      overtimeOnly: overtimeOnly,
      absentOnly: absentOnly,
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
          absenceMarkedByName:
              ((a['markedBy'] as String?)?.trim().isNotEmpty ?? false)
                  ? a['markedBy'] as String?
                  : d.absenceMarkedByName,
        );
      }).toList();
      return profile.copyWith(days: enrichedDays);
    } catch (e, st) {
      AppLogger.e('Av2 absence backfill failed (showing profile as-is)', e, st);
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
    // The host repository is typed now (it used to hand back the raw body),
    // so the records arrive as entities and the shape below is built from
    // their fields rather than from map keys.
    final body = await _attendanceSource.fetchStaffAttendanceProfileAbsentToggle(
      query: AttendanceProfileAbsentToggleQuery(
        staffCode: staffCode,
        fromAbsenceDate: _fmt(from),
        toAbsenceDate: _fmt(to),
        page: 0,
        size: Av2Config.profilePageSize,
        sort: const <String>['absenceDate,desc'],
        includePageableAliasParams: true,
      ),
    );
    final records = body?.records ?? const [];
    return records.map((r) {
      return <String, dynamic>{
        'code': r.code,
        'date': DateTime.tryParse(r.absenceDate),
        'from': DateTime.tryParse(r.absenceFromDate ?? ''),
        'to': DateTime.tryParse(r.absenceToDate ?? ''),
        'reason': r.absenceReason,
        'type': r.absenceType,
        'note': r.absenceNote,
        'markedBy': (r.markedAbsentByName ?? r.markedAbsentBy)?.toString(),
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
      query: AttendanceProfileQuery(
        staffCode: staffCode,
        fromAttendanceDate: day,
        toAttendanceDate: day,
        page: 0,
        size: Av2Config.profilePageSize,
      ),
    );
    // The host repository returns typed records now; DayDetailMapper still
    // reads the wire shape, so the records are handed back to it in that
    // shape rather than duplicating its session/break derivation here.
    return DayDetailMapper.fromResponse(<String, dynamic>{
      'records': <String, dynamic>{
        'content': [
          for (final r in body?.records ?? const [])
            <String, dynamic>{
              'code': r.code,
              'classroomName': r.classroomName,
              'signedInTime': r.signedInTime,
              'signedOutTime': r.signedOutTime,
              'signedInBy': r.signedInBy,
              'signedOutBy': r.signedOutBy,
              'signedOutMethod': r.signedOutMethod,
              'attendedHours': r.attendedHours,
              'attendedMinutes': r.attendedMinutes,
            },
        ],
      },
    }, date);
  }

  @override
  Future<void> editSession({
    required String recordCode,
    required String staffCode,
    required DateTime signInLocal,
    DateTime? signOutLocal,
    required String timeZone,
  }) async {
    final zone = await _schoolZone(timeZone);
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

  /// The school's IANA zone for converting picked wall-clock times to UTC.
  ///
  /// Never the overview's `period.timeZone` when the school zone is known:
  /// that field can carry the admin's zone (e.g. Asia/Kolkata for a New York
  /// school), which shifts every edited instant — even onto the previous day.
  /// [fallback] is used only if the school zone can't be resolved.
  Future<String> _schoolZone(String fallback) async {
    String school;
    try {
      school = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: serviceLocator<StorageService>(),
        apiClient: serviceLocator<ApiClient>(),
      );
    } catch (e) {
      AppLogger.w('Av2 school timezone resolve failed: $e');
      school = SchoolTimezoneResolver.lastKnownTimeZone;
    }
    final resolved =
        school.trim().isEmpty ||
            school.trim() == SchoolTimezoneResolver.fallbackTimeZone
        ? fallback
        : school;
    return Av2TimeZone.resolveZone(resolved);
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
    } catch (e, st) {
      AppLogger.e('Av2 absent-days shift sync failed (absence edit kept)', e, st);
    }
  }

  @override
  Future<void> deleteAbsence({
    required String code,
    required String staffCode,
  }) {
    return _overviewSource.deleteAbsence(code: code, staffCode: staffCode);
  }

  @override
  Future<List<Av2StaffSummary>> getStaff() async {
    final sl = serviceLocator<StorageService>();
    final school =
        (await sl.getString(StorageKeys.schoolCode) ?? '').trim();
    if (school.isEmpty) return const [];
    final org =
        (await sl.getString(StorageKeys.organizationCode) ?? '').trim();
    final raw = await _overviewSource.getStaffRaw(
      schoolCode: school,
      organizationCode: org,
    );
    return raw
        .map((m) => Av2StaffSummary(
              code: (m['code'] as String?) ?? '',
              name: (m['name'] as String?) ?? '',
              designation: (m['designation'] as String?) ?? '',
              classroomName: (m['classroom'] as String?) ?? '',
            ))
        .toList();
  }

  @override
  Future<List<Av2Classroom>> getClassrooms() async {
    final schoolCode =
        (await serviceLocator<StorageService>().getString(StorageKeys.schoolCode) ?? '')
            .trim();
    if (schoolCode.isEmpty) return const [];
    final raw = await _overviewSource.getClassroomsRaw(schoolCode: schoolCode);
    return raw
        .map((m) => Av2Classroom(
              code: (m['code'] as String?) ?? '',
              name: (m['name'] as String?) ?? '',
            ))
        .toList();
  }

  @override
  Future<void> addAttendance({
    required String staffCode,
    required DateTime date,
    required String timeZone,
    String? signInClassroomCode,
    DateTime? signInLocal,
    String? signOutClassroomCode,
    DateTime? signOutLocal,
  }) async {
    final zone = await _schoolZone(timeZone);
    final dateStr = _fmt(date);
    if (signInLocal != null && signInClassroomCode != null) {
      await _overviewSource.signIn(
        staffCode: staffCode,
        classroomCode: signInClassroomCode,
        attendanceDate: dateStr,
        occurredAtUtc: Av2TimeZone.toUtcIso(signInLocal, zone),
        timeZone: zone,
      );
    }
    if (signOutLocal != null && signOutClassroomCode != null) {
      await _overviewSource.signOut(
        staffCode: staffCode,
        classroomCode: signOutClassroomCode,
        attendanceDate: dateStr,
        occurredAtUtc: Av2TimeZone.toUtcIso(signOutLocal, zone),
        timeZone: zone,
      );
    }
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
