import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

/// A stand-in for `AttendanceSource` with a small, legible day on it: three
/// students across two classrooms, and two staff.
///
/// Every outcome is a field, so a test says what came back rather than
/// arranging for it. `mocktail` is available; a hand-written double reads
/// better here because the source has one shape and eleven methods.
class FakeAttendanceSource implements AttendanceSource {
  AttendanceDayResult dayResult = AttendanceDayLoaded(defaultSnapshot);
  RangePage range = defaultRangePage;
  bool insideGeofence = true;

  bool throwsOnRead = false;
  bool throwsOnWrite = false;

  /// What the last call was handed, so a test can check the form sends what
  /// the screen showed.
  DateTime? lastSignedAt;
  List<String> lastIds = const <String>[];
  String? lastReason;
  String? lastTransferTo;
  int loadDayCalls = 0;
  int loadRangeCalls = 0;

  SelfShift selfShift = const SelfShift(
    initials: 'DW',
    classroomName: 'Sunflower',
    shiftStart: ClockTime(8, 0),
    coverName: 'Jamal Ortiz',
    coverArrives: ClockTime(12, 0),
  );

  // --- The fixtures ---------------------------------------------------------

  static const AttendanceRecord aria = AttendanceRecord(
    id: 'aria',
    fullName: 'Aria Rowan',
    initials: 'AR',
    audience: AttendanceAudience.students,
    status: AttendanceStatus.signedIn,
    classroomName: 'Sunflower',
    isExpectedToday: true,
    signedInTime: ClockTime(8, 12),
    signedInBy: 'Dana Whitfield',
    signedInMethod: AttendanceMethod.pin,
  );

  static const AttendanceRecord jonah = AttendanceRecord(
    id: 'jonah',
    fullName: 'Jonah Park',
    initials: 'JP',
    audience: AttendanceAudience.students,
    status: AttendanceStatus.notMarked,
    classroomName: 'Sunflower',
    isExpectedToday: false,
  );

  static const AttendanceRecord rumi = AttendanceRecord(
    id: 'rumi',
    fullName: 'Rumi Tanaka',
    initials: 'RT',
    audience: AttendanceAudience.students,
    status: AttendanceStatus.signedOut,
    classroomName: 'Bluebell',
    isExpectedToday: true,
    signedInTime: ClockTime(8, 2),
    signedOutTime: ClockTime(12, 7),
    signedOutBy: 'Priya Raman',
    signedOutMethod: AttendanceMethod.app,
  );

  static const AttendanceRecord felix = AttendanceRecord(
    id: 'felix',
    fullName: 'Felix Duarte',
    initials: 'FD',
    audience: AttendanceAudience.students,
    status: AttendanceStatus.absent,
    classroomName: 'Bluebell',
    isExpectedToday: true,
    absenceReason: 'Family holiday, booked 4 Aug',
  );

  static const AttendanceRecord dana = AttendanceRecord(
    id: 'dana',
    fullName: 'Dana Whitfield',
    initials: 'DW',
    audience: AttendanceAudience.staff,
    status: AttendanceStatus.signedIn,
    classroomName: 'Sunflower',
    roleLabel: 'Lead Teacher · Sunflower · 8:00 to 4:00',
    isExpectedToday: true,
    expectedTime: ClockTime(8, 0),
    signedInTime: ClockTime(7, 48),
    signedInBy: 'Dana Whitfield',
    signedInMethod: AttendanceMethod.gps,
  );

  static const AttendanceRecord jamal = AttendanceRecord(
    id: 'jamal',
    fullName: 'Jamal Ortiz',
    initials: 'JO',
    audience: AttendanceAudience.staff,
    status: AttendanceStatus.notMarked,
    classroomName: 'Sunflower · Bluebell',
    roleLabel: 'Assistant Teacher · Sunflower · 12:00 to 6:00',
    isExpectedToday: true,
    expectedTime: ClockTime(12, 0),
  );

  static const AttendanceSnapshot defaultSnapshot = AttendanceSnapshot(
    rows: <AttendanceRecord>[aria, jonah, rumi, felix],
    classroomNames: <String>['Sunflower', 'Bluebell'],
    enrolled: <String, int>{'Sunflower': 2, 'Bluebell': 2},
    allowedRatio: <String, int>{'Sunflower': 8, 'Bluebell': 6},
    staffPresent: <String, int>{'Sunflower': 1, 'Bluebell': 0},
    schoolClassroomCount: 5,
    studentsTotal: 4,
    studentsSignedIn: 1,
    staffTotal: 2,
    staffSignedIn: 1,
    staffMinutesToday: 113,
  );

  static const AttendanceSnapshot staffSnapshot = AttendanceSnapshot(
    rows: <AttendanceRecord>[dana, jamal],
    classroomNames: <String>['Sunflower', 'Bluebell'],
    enrolled: <String, int>{'Sunflower': 2, 'Bluebell': 2},
    schoolClassroomCount: 5,
    studentsTotal: 4,
    studentsSignedIn: 1,
    staffTotal: 2,
    staffSignedIn: 1,
    staffMinutesToday: 113,
    staffGap: StaffGap(
      classroomName: 'Bluebell',
      at: ClockTime(11, 30),
      body: 'Priya is the only staff member left with six toddlers in.',
    ),
  );

  static const RangeEntry danaRange = RangeEntry(
    id: 'dana',
    fullName: 'Dana Whitfield',
    initials: 'DW',
    classroomName: 'Sunflower',
    audience: AttendanceAudience.staff,
    attendedHours: 128,
    attendedMinutes: 40,
    attendedDays: 16,
  );

  static const RangeEntry priyaRange = RangeEntry(
    id: 'priya',
    fullName: 'Priya Raman',
    initials: 'PR',
    classroomName: 'Bluebell',
    audience: AttendanceAudience.staff,
    attendedHours: 119,
    attendedMinutes: 20,
    attendedDays: 15,
  );

  static const RangePage defaultRangePage = RangePage(
    entries: <RangeEntry>[danaRange, priyaRange],
    page: 0,
    totalElements: 3,
    hasMore: true,
  );

  static const RangePage lastRangePage = RangePage(
    entries: <RangeEntry>[
      RangeEntry(
        id: 'tomas',
        fullName: 'Tomas Berg',
        initials: 'TB',
        classroomName: 'Bluebell',
        audience: AttendanceAudience.staff,
        attendedHours: 64,
        attendedMinutes: 15,
        attendedDays: 8,
      ),
    ],
    page: 1,
    totalElements: 3,
    hasMore: false,
  );

  /// A guardian's own children, and the month behind them.
  static const AttendanceSnapshot guardianSnapshot = AttendanceSnapshot(
    rows: <AttendanceRecord>[aria],
    classroomNames: <String>['Sunflower'],
    studentsTotal: 1,
    studentsSignedIn: 1,
    children: <GuardianChildAttendance>[
      GuardianChildAttendance(
        today: aria,
        days: <GuardianDay>[
          GuardianDay(
            dateLabel: 'Wed 19 Aug',
            detail: '8:35 to 3:40 · you collected Aria',
            trailing: '7h 5m',
            status: AttendanceStatus.signedOut,
          ),
        ],
        daysIn: 13,
        daysAbsent: 1,
        hours: 91,
      ),
    ],
  );

  // --- AttendanceSource -----------------------------------------------------

  @override
  Future<AttendanceDayResult> loadDay({
    required Persona persona,
    required AttendanceAudience audience,
    required DateTime day,
    String? scopeClassroom,
    String query = '',
  }) async {
    loadDayCalls++;
    if (throwsOnRead) throw Exception('no');
    return dayResult;
  }

  @override
  Future<List<String>> classroomNames() async => const <String>[
    'Sunflower',
    'Bluebell',
    'Acorn',
  ];

  @override
  Future<RangePage> loadRange({
    required AttendanceAudience audience,
    required DateRange range,
    Set<String> classrooms = const <String>{},
    String query = '',
    int page = 0,
  }) async {
    loadRangeCalls++;
    if (throwsOnRead) throw Exception('no');
    return page == 0 ? this.range : lastRangePage;
  }

  @override
  Future<bool> isInsideGeofence() async => insideGeofence;

  @override
  Future<SelfShift> signSelfIn() async {
    if (throwsOnWrite) throw Exception('no');
    return selfShift = selfShift.copyWith(signedInAt: const ClockTime(7, 48));
  }

  @override
  Future<SelfShift> signSelfOut() async {
    if (throwsOnWrite) throw Exception('no');
    return selfShift = selfShift.copyWith(signedOutAt: const ClockTime(16, 2));
  }

  @override
  Future<void> signIn({
    required List<String> ids,
    required AttendanceAudience audience,
    required DateTime at,
  }) async {
    if (throwsOnWrite) throw Exception('no');
    lastIds = ids;
    lastSignedAt = at;
  }

  @override
  Future<void> signOut({
    required List<String> ids,
    required AttendanceAudience audience,
    required DateTime at,
  }) async {
    if (throwsOnWrite) throw Exception('no');
    lastIds = ids;
    lastSignedAt = at;
  }

  @override
  Future<void> markAbsent({
    required List<String> ids,
    required DateTime date,
    required String reason,
  }) async {
    if (throwsOnWrite) throw Exception('no');
    lastIds = ids;
    lastReason = reason;
  }

  @override
  Future<void> undoAbsence(String id) async {
    if (throwsOnWrite) throw Exception('no');
    lastIds = <String>[id];
  }

  @override
  Future<void> transfer({
    required String id,
    required String toClassroom,
  }) async {
    if (throwsOnWrite) throw Exception('no');
    lastIds = <String>[id];
    lastTransferTo = toClassroom;
  }

  @override
  Future<void> editTimes({
    required String id,
    required DateTime at,
    required bool isSignOut,
  }) async {
    if (throwsOnWrite) throw Exception('no');
    lastIds = <String>[id];
    lastSignedAt = at;
  }
}
