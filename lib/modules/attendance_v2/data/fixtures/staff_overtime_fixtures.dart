import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/day_detail.dart';
import '../../domain/entities/staff_overtime_profile.dart';

/// Static sample data for the static-screen preview / tests. Mirrors the new
/// two-call shape: overview days (no sessions) + a lazily-loaded [DayDetail]
/// per date.
class StaffOvertimeFixtures {
  const StaffOvertimeFixtures._();

  static StaffOvertimeProfile get sample => StaffOvertimeProfile(
        staffCode: 'STF_DEMO',
        staffName: 'Devi Vempati',
        designation: 'Teacher',
        classroomName: '4-Yellow-D',
        todayStatus: TodayStatus.present,
        dailyRegularMinutes: 480,
        rangeStart: DateTime(2026, 6, 1),
        rangeEnd: DateTime(2026, 6, 30),
        aggregation: const OvertimeAggregation(
          attendedDays: 8,
          absentDays: 2,
          totalRegularMinutes: 3840,
          totalOvertimeMinutes: 423,
          totalBreakMinutes: 71,
        ),
        days: [
          _day('2026-06-12', DayStatus.absent),
          _day('2026-06-11', DayStatus.signedOut,
              regular: 480, ot: 16, brk: 71, needsAttention: true),
          _day('2026-06-10', DayStatus.signedOut, regular: 480, ot: 85),
          _day('2026-06-08', DayStatus.signedOut, regular: 480, ot: 81),
          _day('2026-06-05', DayStatus.signedIn, regular: 480, ot: 0, needsAttention: true),
          _day('2026-06-04', DayStatus.signedOut, regular: 480, ot: 150),
          _day('2026-06-03', DayStatus.signedOut, regular: 480, ot: 89),
          _day('2026-06-02', DayStatus.signedOut, regular: 480, ot: 79),
          _day('2026-06-01', DayStatus.signedOut, regular: 480, ot: 86),
        ],
      );

  static AttendanceDay _day(
    String date,
    DayStatus status, {
    int regular = 0,
    int ot = 0,
    int brk = 0,
    bool needsAttention = false,
  }) {
    return AttendanceDay(
      date: DateTime.parse(date),
      status: status,
      regularMinutes: regular,
      overtimeMinutes: ot,
      breakMinutes: brk,
      totalMinutes: regular + ot,
      hasOvertime: ot > 0,
      needsAttention: needsAttention,
    );
  }

  /// Fake lazy detail for the preview/tests. Jun 11 returns 3 sessions + 2
  /// breaks (incl. a System auto-close); other days a single plain session.
  static DayDetail dayDetail(DateTime date) {
    DateTime at(int h, int m) => DateTime(date.year, date.month, date.day, h, m);
    if (date.month == 6 && date.day == 11) {
      final sessions = [
        AttendanceSession(
          recordCode: 'AR_1101', classroomName: 'Office',
          signInAt: at(8, 0), signOutAt: at(10, 0),
          signedInBy: 'Spandana', signedOutBy: 'Spandana',
          signOutSource: SignOutSource.staff, workedMinutes: 120,
        ),
        AttendanceSession(
          recordCode: 'AR_1102', classroomName: '6-Yellow-P',
          signInAt: at(10, 40), signOutAt: at(13, 0),
          signedInBy: 'Spandana', signedOutBy: 'Spandana',
          signOutSource: SignOutSource.staff, workedMinutes: 140,
        ),
        AttendanceSession(
          recordCode: 'AR_1103', classroomName: '6-Yellow-P',
          signInAt: at(13, 31), signOutAt: at(17, 27),
          signedInBy: 'Spandana', signedOutBy: 'System',
          signOutSource: SignOutSource.system, workedMinutes: 236,
        ),
      ];
      return DayDetail(
        sessions: sessions,
        breaks: [
          AttendanceBreak(start: at(10, 0), end: at(10, 40), minutes: 40),
          AttendanceBreak(start: at(13, 0), end: at(13, 31), minutes: 31),
        ],
      );
    }
    return DayDetail(
      sessions: [
        AttendanceSession(
          recordCode: 'AR_${date.day}', classroomName: '4-Yellow-D',
          signInAt: at(8, 0), signOutAt: at(17, 30),
          signedInBy: 'Devi', signedOutBy: 'Devi',
          signOutSource: SignOutSource.staff, workedMinutes: 570,
        ),
      ],
      breaks: const [],
    );
  }
}
