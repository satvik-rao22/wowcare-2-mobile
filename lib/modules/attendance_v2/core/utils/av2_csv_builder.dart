import 'dart:convert';
import 'package:intl/intl.dart';

import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/day_detail.dart';
import '../../domain/entities/staff_overtime_profile.dart';

/// Builds the staff attendance & overtime export as a clean, Excel-friendly CSV
/// that mirrors the on-screen hierarchy:
///
///   ① Report meta block  — staff identity + range
///   ② Summary block      — the hero totals (regular / overtime / break split)
///   ③ Daily detail       — one **day summary row**, with its **sessions and the
///                          breaks between them nested beneath** (`↳ Session` /
///                          `↳ Break`), exactly like the cards.
///
/// Break time is the **sum of the gaps between that day's sessions** (computed
/// from the sessions, not the server rollup). Durations are human-readable
/// (`8hr 40min`). CRLF + UTF-8 BOM keep it Excel-compatible on Windows/macOS.
class Av2CsvBuilder {
  const Av2CsvBuilder._();

  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _day = DateFormat('EEE');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _stamp = DateFormat('yyyy-MM-dd HH:mm');

  /// UTF-8 bytes (BOM-prefixed) ready to write to a `.csv` file.
  static List<int> buildBytes({
    required StaffOvertimeProfile profile,
    required Map<String, DayDetail> detailByDate,
    required String reportLabel,
    required DateTime generatedAt,
  }) {
    final csv = build(
      profile: profile,
      detailByDate: detailByDate,
      reportLabel: reportLabel,
      generatedAt: generatedAt,
    );
    return utf8.encode('﻿$csv');
  }

  static String build({
    required StaffOvertimeProfile profile,
    required Map<String, DayDetail> detailByDate,
    required String reportLabel,
    required DateTime generatedAt,
  }) {
    final rows = <List<String>>[];
    void kv(String key, String value) => rows.add([key, value]);

    final a = profile.aggregation;
    final days = [...profile.days]..sort((x, y) => x.date.compareTo(y.date));

    // Break = sum of session gaps; total break is the sum across days so the
    // summary and the per-day rows always agree.
    final breakByDay = <AttendanceDay, int>{};
    var totalBreak = 0;
    for (final d in days) {
      final mins = _dayBreakMinutes(d, detailByDate);
      breakByDay[d] = mins;
      totalBreak += mins;
    }

    // ① Report meta
    rows.add(['Staff Attendance & Overtime Report']);
    kv('Staff', profile.staffName);
    kv('Designation', profile.designation);
    kv('Classroom', profile.classroomName);
    kv('Date Range',
        '${_date.format(profile.rangeStart)} to ${_date.format(profile.rangeEnd)}');
    kv('Report', reportLabel);
    kv('Generated', _stamp.format(generatedAt));
    rows.add(['']);

    // ② Summary (mirrors the hero card)
    rows.add(['Summary']);
    kv('Attended days', '${a.attendedDays}');
    kv('Absent days', '${a.absentDays}');
    kv('Regular', _hm(a.totalRegularMinutes));
    kv('Overtime', _hm(a.totalOvertimeMinutes));
    kv('Break', _hm(totalBreak));
    kv('Total Worked', _hm(a.totalAttendedMinutes));
    kv('Avg / Attended Day', _hm(a.averageMinutesPerDay));
    rows.add(['']);

    // ③ Daily detail — day summary rows with sessions + breaks nested beneath.
    rows.add(['Daily detail']);
    rows.add([
      'Date',
      'Day',
      'Status',
      'In',
      'Out',
      'Room',
      'Regular',
      'Overtime',
      'Break',
      'Total',
      'Note',
    ]);
    for (final d in days) {
      rows.addAll(_dayBlock(d, detailByDate, breakByDay[d] ?? 0));
    }

    return rows.map(_encodeRow).join('\r\n');
  }

  /// A day summary row, followed by its `↳ Session` / `↳ Break` sub-rows.
  static List<List<String>> _dayBlock(
    AttendanceDay d,
    Map<String, DayDetail> details,
    int breakMinutes,
  ) {
    final date = _date.format(d.date);
    final day = _day.format(d.date);

    if (d.isAbsent) {
      return [
        [date, day, 'Absent', '', '', '', '', '', '', '', _absenceNote(d)],
      ];
    }
    if (d.status == DayStatus.notMarked) {
      return [
        [date, day, 'Not Marked', '', '', '', '', '', '', '', ''],
      ];
    }

    final status = d.status == DayStatus.signedIn ? 'Signed In' : 'Signed Out';
    final block = <List<String>>[
      [
        date, day, status, '', '', '',
        _hm(d.regularMinutes),
        _hm(d.overtimeMinutes),
        _hm(breakMinutes),
        _hm(d.totalMinutes),
        '',
      ],
    ];

    final sessions = _sessionsFor(d, details);
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      block.add([
        '', '', '↳ Session',
        _time.format(s.signInAt),
        s.isOpen ? 'Open' : _time.format(s.signOutAt!),
        s.classroomName,
        '', '', '',
        _hm(s.workedMinutes),
        '',
      ]);
      // Break row = gap to the next session (if any).
      if (i < sessions.length - 1 && s.signOutAt != null) {
        final gap = sessions[i + 1].signInAt.difference(s.signOutAt!).inMinutes;
        if (gap > 0) {
          block.add([
            '', '', '↳ Break',
            _time.format(s.signOutAt!),
            _time.format(sessions[i + 1].signInAt),
            '', '', '',
            _hm(gap),
            '', '',
          ]);
        }
      }
    }
    return block;
  }

  static List<AttendanceSession> _sessionsFor(
    AttendanceDay d,
    Map<String, DayDetail> details,
  ) =>
      details['${d.date.year}-${d.date.month}-${d.date.day}']?.sessions ??
      const [];

  /// Sum of the gaps between a day's sessions; falls back to the server rollup
  /// when the day's detail wasn't fetched.
  static int _dayBreakMinutes(AttendanceDay d, Map<String, DayDetail> details) {
    if (d.isAbsent || d.status == DayStatus.notMarked) return 0;
    final sessions = _sessionsFor(d, details);
    if (sessions.isEmpty) return d.breakMinutes;
    var total = 0;
    for (var i = 0; i < sessions.length - 1; i++) {
      final out = sessions[i].signOutAt;
      if (out == null) continue;
      final gap = sessions[i + 1].signInAt.difference(out).inMinutes;
      if (gap > 0) total += gap;
    }
    return total;
  }

  /// "SICK · not present today · Marked by Suhas Biwalkar" — like the absent tile.
  static String _absenceNote(AttendanceDay d) {
    final parts = <String>[
      if ((d.absenceReason ?? '').trim().isNotEmpty) d.absenceReason!.trim(),
      if ((d.absenceNote ?? '').trim().isNotEmpty) d.absenceNote!.trim(),
      if ((d.absenceMarkedByName ?? '').trim().isNotEmpty)
        'Marked by ${d.absenceMarkedByName!.trim()}',
    ];
    return parts.join(' · ');
  }

  /// Human duration, e.g. `8hr 40min`, `0hr 40min`.
  static String _hm(int minutes) {
    final m = minutes < 0 ? 0 : minutes;
    return '${m ~/ 60}hr ${m % 60}min';
  }

  static String _encodeRow(List<String> cells) => cells.map(_escape).join(',');

  /// RFC-4180 escaping: wrap in quotes if the value contains a quote, comma or
  /// line break; double up embedded quotes.
  static String _escape(String v) {
    if (v.contains('"') ||
        v.contains(',') ||
        v.contains('\n') ||
        v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
