import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_csv_builder.dart';
import 'package:wowcare/modules/attendance_v2/domain/entities/attendance_day.dart';
import 'package:wowcare/modules/attendance_v2/domain/entities/attendance_session.dart';
import 'package:wowcare/modules/attendance_v2/domain/entities/day_detail.dart';
import 'package:wowcare/modules/attendance_v2/domain/entities/staff_overtime_profile.dart';

StaffOvertimeProfile _profile(List<AttendanceDay> days) => StaffOvertimeProfile(
      staffCode: 'STF_1',
      staffName: 'Aparna Biwalkar',
      designation: 'Associate Teacher',
      classroomName: 'Office',
      todayStatus: TodayStatus.notMarked,
      dailyRegularMinutes: 480,
      rangeStart: DateTime(2026, 6, 1),
      rangeEnd: DateTime(2026, 6, 30),
      timeZone: 'America/New_York',
      aggregation: const OvertimeAggregation(
        attendedDays: 1,
        absentDays: 1,
        totalRegularMinutes: 480,
        totalOvertimeMinutes: 40,
        totalBreakMinutes: 30,
      ),
      days: days,
    );

void main() {
  test('builds meta + summary + session/absent rows', () {
    final attended = AttendanceDay(
      date: DateTime(2026, 6, 24),
      status: DayStatus.signedOut,
      regularMinutes: 480,
      overtimeMinutes: 40,
      breakMinutes: 30,
      totalMinutes: 520,
      hasOvertime: true,
    );
    final absent = AttendanceDay(
      date: DateTime(2026, 6, 26),
      status: DayStatus.absent,
      regularMinutes: 0,
      overtimeMinutes: 0,
      breakMinutes: 0,
      totalMinutes: 0,
      hasOvertime: false,
      absenceCode: 'SFAR_1',
      absenceReason: 'SICK',
      absenceNote: 'not present today',
      absenceMarkedByName: 'Suhas Biwalkar',
    );
    final detail = DayDetail(
      sessions: [
        AttendanceSession(
          recordCode: 'R1',
          classroomName: 'Office',
          signInAt: DateTime(2026, 6, 24, 9, 0),
          signOutAt: DateTime(2026, 6, 24, 12, 0),
          signedInBy: 'Self',
          signedOutBy: 'Self',
          signOutSource: SignOutSource.staff,
          workedMinutes: 180,
        ),
        AttendanceSession(
          recordCode: 'R2',
          classroomName: 'Office',
          signInAt: DateTime(2026, 6, 24, 12, 30),
          signOutAt: DateTime(2026, 6, 24, 17, 40),
          signedInBy: 'Self',
          signedOutBy: 'Self',
          signOutSource: SignOutSource.staff,
          workedMinutes: 310,
        ),
      ],
      breaks: const [],
    );

    final csv = Av2CsvBuilder.build(
      profile: _profile([absent, attended]),
      detailByDate: {'2026-6-24': detail},
      reportLabel: 'All days',
      generatedAt: DateTime(2026, 6, 26, 14, 30),
    );

    // Meta + summary (human durations, no timezone row). Break = session gap.
    expect(csv, contains('Staff,Aparna Biwalkar'));
    expect(csv, isNot(contains('Timezone')));
    expect(csv, contains('Overtime,0hr 40min'));
    expect(csv, contains('Break,0hr 30min'));
    expect(csv, contains('Total Worked,8hr 40min'));
    // Data header (now with In By / Out By columns).
    expect(csv,
        contains('Date,Day,Status,In,In By,Out,Out By,Room,Regular,Overtime,Break,Total,Note'));
    // Day summary row (break = the 30-min gap between sessions).
    expect(csv,
        contains('2026-06-24,Wed,Signed Out,,,,,,8hr 0min,0hr 40min,0hr 30min,8hr 40min,'));
    // Sessions carry who signed in/out; break between them is nested.
    expect(csv,
        contains(',,↳ Session,9:00 AM,Self,12:00 PM,Self,Office,,,,3hr 0min,'));
    expect(csv, contains(',,↳ Break,12:00 PM,,12:30 PM,,,,,0hr 30min,,'));
    expect(csv,
        contains(',,↳ Session,12:30 PM,Self,5:40 PM,Self,Office,,,,5hr 10min,'));
    // Absent row carries reason · note · marked-by in one note cell.
    expect(csv,
        contains('2026-06-26,Fri,Absent,,,,,,,,,,SICK · not present today · Marked by Suhas Biwalkar'));
    // CRLF line endings.
    expect(csv, contains('\r\n'));
  });

  test('quotes fields containing commas', () {
    final absent = AttendanceDay(
      date: DateTime(2026, 6, 26),
      status: DayStatus.absent,
      regularMinutes: 0,
      overtimeMinutes: 0,
      breakMinutes: 0,
      totalMinutes: 0,
      hasOvertime: false,
      absenceCode: 'SFAR_1',
      absenceReason: 'OTHER',
      absenceNote: 'sick, then travel',
      absenceMarkedByName: 'Admin',
    );
    final csv = Av2CsvBuilder.build(
      profile: _profile([absent]),
      detailByDate: const {},
      reportLabel: 'Absent',
      generatedAt: DateTime(2026, 6, 26, 14, 30),
    );
    // The whole note cell (which contains a comma) is wrapped in quotes.
    expect(csv,
        contains('"OTHER · sick, then travel · Marked by Admin"'));
  });

  test('byte output is UTF-8 BOM prefixed', () {
    final bytes = Av2CsvBuilder.buildBytes(
      profile: _profile(const []),
      detailByDate: const {},
      reportLabel: 'All days',
      generatedAt: DateTime(2026, 6, 26, 14, 30),
    );
    expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
  });
}
