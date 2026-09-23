import 'package:wowcare/core/utils/logger_service.dart';

import '../../core/config/av2_config.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/staff_overtime_profile.dart';

/// Maps the `/staff-overtime-records/profile` response (per-day rollups,
/// server-computed) into the module's profile + day list. No client-side
/// overtime math — the server already split regular/overtime/break per day.
///
/// Parsing here is **tolerant by design**: a field arriving as a number where
/// a string was expected (or `days` arriving wrapped in a page envelope) must
/// degrade that one field, never throw. A throw here reaches the screen as the
/// generic "Something went wrong" with no API error log — invisible to debug.
class OverviewMapper {
  const OverviewMapper._();

  static StaffOvertimeProfile fromResponse(
    Map<String, dynamic>? body, {
    required String fallbackStaffCode,
    required String fallbackStaffName,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    try {
      return _map0(
        body,
        fallbackStaffCode: fallbackStaffCode,
        fallbackStaffName: fallbackStaffName,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    } catch (e, st) {
      // Dump the response *shape* (keys → runtime types, no values) so the
      // offending field is identifiable from the log alone.
      AppLogger.e('Av2 overview mapping failed — ${_shape(body)}', e, st);
      rethrow;
    }
  }

  static StaffOvertimeProfile _map0(
    Map<String, dynamic>? body, {
    required String fallbackStaffCode,
    required String fallbackStaffName,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final data = _map(body?['data']);
    final staff = _map(data['staff']);
    final period = _map(data['period']);
    final summary = _map(data['summary']);
    final daysJson = _list(data['days']);

    if (data.isEmpty) {
      AppLogger.w('Av2 overview: response has no `data` — ${_shape(body)}');
    } else if (daysJson.isEmpty) {
      AppLogger.w(
          'Av2 overview: no `days` in response — ${_shape(body)}');
    }

    final days = daysJson
        .whereType<Map>()
        .map((e) => _mapDay(e.cast<String, dynamic>()))
        .whereType<AttendanceDay>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    final staffName = _str(staff['staffName']);
    return StaffOvertimeProfile(
      staffCode: _str(staff['staffCode']) ?? fallbackStaffCode,
      staffName: (staffName?.isNotEmpty ?? false) ? staffName! : fallbackStaffName,
      designation: _humanize(staff['designation']),
      classroomName: _str(staff['classroomName']) ?? '',
      todayStatus: _parseTodayStatus(_str(staff['todayStatus'])),
      dailyRegularMinutes: Av2Config.defaultDailyRegularMinutes,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      aggregation: _aggregation(summary, days),
      days: days,
      timeZone: _str(period['timeZone']) ?? '',
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  /// Accepts a plain list **or** a paginated envelope
  /// (`{content: [...]}` / `{records: [...]}` / `{items: [...]}`) — the
  /// backend's list endpoints use both shapes.
  static List<dynamic> _list(dynamic v) {
    if (v is List) return v;
    if (v is Map) {
      for (final key in const ['content', 'records', 'items', 'days']) {
        final inner = v[key];
        if (inner is List) return inner;
      }
    }
    return const [];
  }

  /// Coerces any scalar to a trimmed string (so a numeric `staffCode` or an
  /// enum object does not blow up a hard `as String` cast). `null` stays null.
  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.trim();
    if (v is num || v is bool) return v.toString();
    return null;
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.trim().toLowerCase() == 'true';
    return false;
  }

  /// Parses a date that may arrive as `"2026-06-11"`, an ISO instant, or a
  /// Jackson date array `[2026, 6, 11]`.
  static DateTime? _date(dynamic v) {
    if (v is String) return DateTime.tryParse(v.trim());
    if (v is List && v.length >= 3) {
      final parts = v.map(_int).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }
    return null;
  }

  static AttendanceDay? _mapDay(Map<String, dynamic> m) {
    final date = _date(m['date']);
    if (date == null) {
      AppLogger.w('Av2 overview: skipping day with unparsable date '
          '(${m['date'].runtimeType}) — keys ${m.keys.toList()}');
      return null;
    }
    final absence = _map(m['absence']);
    return AttendanceDay(
      date: date,
      // `status` is the calculated-record field; `type` is what the overview
      // spec documents (ATTENDED | ABSENT). Accept either.
      status: _parseDayStatus(_str(m['status']) ?? _str(m['type'])),
      regularMinutes: _int(m['regularMinutes']),
      overtimeMinutes: _int(m['overtimeMinutes']),
      breakMinutes: _int(m['breakMinutes']),
      totalMinutes: _int(m['totalMinutes']),
      hasOvertime: _bool(m['hasOvertime']),
      needsAttention: _bool(m['needsAttention']),
      // Absence details — read from a nested `absence` block or flat fields,
      // whichever the overview provides. `code` is what edit/delete target.
      absenceCode: _str(absence['code'] ?? absence['recordCode'] ?? m['absenceCode']),
      absenceReason: _str(absence['reason'] ?? m['absenceReason']),
      absenceType: _str(absence['type'] ?? m['absenceType']),
      absenceFromDate: _date(absence['fromDate'] ?? absence['absenceFromDate']),
      absenceToDate: _date(absence['toDate'] ?? absence['absenceToDate']),
      absenceNote: _str(absence['note'] ?? m['absenceNote']),
      absenceMarkedByName: _str(absence['markedByName'] ?? m['markedByName']),
    );
  }

  /// Uses the server summary; falls back to summing days when the summary is
  /// empty but days carry data (guards backend stubs that return zero summary).
  static OvertimeAggregation _aggregation(
    Map<String, dynamic> summary,
    List<AttendanceDay> days,
  ) {
    var attended = _int(summary['attendedDays']);
    var absent = _int(summary['absentDays']);
    var regular = _int(summary['regularMinutes']);
    var overtime = _int(summary['overtimeMinutes']);
    var breaks = _int(summary['breakMinutes']);

    final summaryEmpty = regular == 0 && overtime == 0 && attended == 0;
    final daysHaveData = days.any((d) => d.totalMinutes > 0);
    if (summaryEmpty && daysHaveData) {
      regular = days.fold(0, (t, d) => t + d.regularMinutes);
      overtime = days.fold(0, (t, d) => t + d.overtimeMinutes);
      breaks = days.fold(0, (t, d) => t + d.breakMinutes);
      attended = days.where((d) => !d.isAbsent && d.totalMinutes > 0).length;
      absent = days.where((d) => d.isAbsent).length;
    }

    return OvertimeAggregation(
      attendedDays: attended,
      absentDays: absent,
      totalRegularMinutes: regular,
      totalOvertimeMinutes: overtime,
      totalBreakMinutes: breaks,
    );
  }

  static DayStatus _parseDayStatus(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'SIGNED_IN':
        return DayStatus.signedIn;
      case 'SIGNED_OUT':
      case 'ATTENDED':
        return DayStatus.signedOut;
      case 'ABSENT':
        return DayStatus.absent;
      default:
        return DayStatus.notMarked;
    }
  }

  static TodayStatus _parseTodayStatus(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'PRESENT':
        return TodayStatus.present;
      case 'SIGNED_OUT':
        return TodayStatus.signedOut;
      case 'ABSENT':
        return TodayStatus.absent;
      default:
        return TodayStatus.notMarked;
    }
  }

  /// "ASSOCIATE_TEACHER" → "Associate Teacher". Accepts string or list.
  static String _humanize(dynamic d) {
    String raw = '';
    if (d is List && d.isNotEmpty) {
      raw = d.first.toString();
    } else if (d is String) {
      raw = d;
    }
    if (raw.trim().isEmpty) return 'Staff';
    return raw
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Keys → runtime types, one level deep (plus the first `days` entry). Types
  /// only, never values — safe to log and enough to spot a contract mismatch.
  static String _shape(dynamic v, [int depth = 0]) {
    if (v is Map) {
      final entries = v.entries.map((e) {
        final nested = (depth < 2 && (e.value is Map || e.value is List))
            ? _shape(e.value, depth + 1)
            : e.value.runtimeType.toString();
        return '${e.key}: $nested';
      });
      return '{${entries.join(', ')}}';
    }
    if (v is List) {
      if (v.isEmpty) return 'List(empty)';
      return 'List(${v.length})[${_shape(v.first, depth + 1)}]';
    }
    return v.runtimeType.toString();
  }
}
