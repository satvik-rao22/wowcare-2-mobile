import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/staff_overtime_profile.dart';

/// Static sample data for the design / static-screen phase. Mirrors the
/// shape the real API will return so swapping to a remote datasource later
/// is mechanical. Numbers match the reference screenshots (Devi Vempati).
class StaffOvertimeFixtures {
  const StaffOvertimeFixtures._();

  static DateTime _d(int day, int h, int m) => DateTime(2026, 6, day, h, m);

  static StaffOvertimeProfile get sample => StaffOvertimeProfile(
    staffCode: 'DV001',
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
      totalRegularMinutes: 3840, // 64h
      totalOvertimeMinutes: 423, // 7h 3m
      totalBreakMinutes: 71,
    ),
    days: [
      AttendanceDay(
        date: DateTime(2026, 6, 12),
        isAbsent: true,
        absenceMarkedBy: 'Spandana Marri',
        absenceNote: '',
      ),
      AttendanceDay(
        // 3 sessions, 2 breaks (40m + 31m = 1h 11m), worked 8h 16m.
        date: DateTime(2026, 6, 11),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 16,
        hasSystemClosedSession: true,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_1101',
            classroomName: 'Office',
            signInAt: _d(11, 8, 0),
            signOutAt: _d(11, 10, 0),
            signedInBy: 'Spandana',
            signedOutBy: 'Spandana',
            signOutSource: SignOutSource.staff,
            workedMinutes: 120,
          ),
          AttendanceSession(
            // 40-minute break before this session (10:00 → 10:40).
            recordCode: 'AR_1102',
            classroomName: '6-Yellow-P',
            signInAt: _d(11, 10, 40),
            signOutAt: _d(11, 13, 0),
            signedInBy: 'Spandana',
            signedOutBy: 'Spandana',
            signOutSource: SignOutSource.staff,
            workedMinutes: 140,
          ),
          AttendanceSession(
            // 31-minute lunch break before this session (13:00 → 13:31).
            recordCode: 'AR_1103',
            classroomName: '6-Yellow-P',
            signInAt: _d(11, 13, 31),
            signOutAt: _d(11, 17, 27),
            signedInBy: 'Spandana',
            signedOutBy: 'System',
            signOutSource: SignOutSource.system,
            workedMinutes: 236,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 10),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 85,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_1001',
            classroomName: 'Office',
            signInAt: _d(10, 8, 5),
            signOutAt: _d(10, 17, 30),
            signedInBy: 'Spandana',
            signedOutBy: 'Spandana',
            signOutSource: SignOutSource.staff,
            workedMinutes: 565,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 8),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 81,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_0801',
            classroomName: '5-Pink-D',
            signInAt: _d(8, 8, 30),
            signOutAt: _d(8, 17, 51),
            signedInBy: 'Devi',
            signedOutBy: 'Devi',
            signOutSource: SignOutSource.staff,
            workedMinutes: 561,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 5),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 88,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_0501',
            classroomName: '4-Yellow-D',
            signInAt: _d(5, 8, 2),
            signOutAt: _d(5, 17, 30),
            signedInBy: 'Devi',
            signedOutBy: 'Devi',
            signOutSource: SignOutSource.staff,
            workedMinutes: 568,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 4),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 150,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_0401',
            classroomName: '4-Yellow-D',
            signInAt: _d(4, 8, 0),
            signOutAt: _d(4, 18, 30),
            signedInBy: 'Devi',
            signedOutBy: 'Devi',
            signOutSource: SignOutSource.staff,
            workedMinutes: 630,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 3),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 89,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_0301',
            classroomName: '4-Yellow-D',
            signInAt: _d(3, 8, 1),
            signOutAt: _d(3, 17, 30),
            signedInBy: 'Devi',
            signedOutBy: 'Devi',
            signOutSource: SignOutSource.staff,
            workedMinutes: 569,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 2),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 79,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_0201',
            classroomName: '4-Yellow-D',
            signInAt: _d(2, 8, 6),
            signOutAt: _d(2, 17, 25),
            signedInBy: 'Devi',
            signedOutBy: 'Devi',
            signOutSource: SignOutSource.staff,
            workedMinutes: 559,
          ),
        ],
      ),
      AttendanceDay(
        date: DateTime(2026, 6, 1),
        isAbsent: false,
        regularMinutes: 480,
        overtimeMinutes: 86,
        sessions: [
          AttendanceSession(
            recordCode: 'AR_0101',
            classroomName: '4-Yellow-D',
            signInAt: _d(1, 8, 4),
            signOutAt: _d(1, 17, 30),
            signedInBy: 'Devi',
            signedOutBy: 'Devi',
            signOutSource: SignOutSource.staff,
            workedMinutes: 566,
          ),
        ],
      ),
    ],
  );
}
