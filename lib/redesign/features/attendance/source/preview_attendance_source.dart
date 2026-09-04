import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

/// M04's fixtures: Maple View's day on the day the design draws.
///
/// The people, their statuses and their times are `DemoData`'s, so the
/// Sunflower list here is the same Sunflower the roster shows and the
/// dashboard counts. What attendance adds on top of a roster row is written
/// here, because it belongs to this module and nowhere else: the method every
/// sign in and sign out was taken on, who took it, whether the person was
/// expected today, and the transfer trail.
///
/// Three literals reach 4e's and 4d's states without unplugging anything, the
/// way `PreviewAuthSource` reaches 1a's:
///
/// * searching **`offline`** returns the saved-on-this-phone day, read only;
/// * searching **`empty`** returns a school with nobody on the roll;
/// * searching **`outside`** puts the staff member outside the geofence, so
///   their own sign-in is refused.
class PreviewAttendanceSource implements AttendanceSource {
  PreviewAttendanceSource();

  /// Long enough that the loading ring is seen, short enough to stay out of
  /// the way.
  static const Duration _latency = Duration(milliseconds: 400);
  static const Duration _writeLatency = Duration(milliseconds: 260);

  static const String _offlineQuery = 'offline';
  static const String _emptyQuery = 'empty';
  static const String _outsideQuery = 'outside';

  /// 4f pages as it is scrolled, the way the real range call does.
  static const int _rangePageSize = 6;

  /// The classrooms with a roster in the demo world, and what each allows.
  static const Map<String, int> _enrolled = <String, int>{
    'Sunflower': 14,
    'Bluebell': 9,
  };
  static const Map<String, int> _allowedRatio = <String, int>{
    'Sunflower': 8,
    'Bluebell': 6,
  };

  /// Writes land here and are folded over the fixtures on the next load, so
  /// signing somebody in actually changes the list.
  final Map<String, AttendanceRecord> _written = <String, AttendanceRecord>{};

  SelfShift _selfShift = const SelfShift(
    initials: 'DW',
    classroomName: 'Sunflower',
    shiftStart: ClockTime(8, 0),
    coverName: 'Jamal Ortiz',
    coverArrives: ClockTime(12, 0),
  );

  // --- The day --------------------------------------------------------------

  @override
  Future<AttendanceDayResult> loadDay({
    required Persona persona,
    required AttendanceAudience audience,
    required DateTime day,
    String? scopeClassroom,
    String query = '',
  }) async {
    await Future<void>.delayed(_latency);

    final term = query.trim().toLowerCase();
    if (term == _emptyQuery) {
      return const AttendanceDayLoaded(
        AttendanceSnapshot(
          classroomNames: <String>['Sunflower', 'Bluebell'],
          schoolClassroomCount: 5,
        ),
      );
    }

    if (term == _outsideQuery) {
      _selfShift = _selfShift.copyWith(isInsideGeofence: false);
    }

    final snapshot = _snapshot(
      persona: persona,
      audience: audience,
      scopeClassroom: scopeClassroom,
    );

    if (term == _offlineQuery) {
      return AttendanceDayOffline(
        snapshot: snapshot,
        asOfLabel: '8:02 this morning',
      );
    }
    return AttendanceDayLoaded(snapshot);
  }

  AttendanceSnapshot _snapshot({
    required Persona persona,
    required AttendanceAudience audience,
    String? scopeClassroom,
  }) {
    final students = _students();
    final staff = _staff();

    final rows = switch (persona) {
      Persona.guardian => _guardianRows(students),
      _ when audience.isStudents => <AttendanceRecord>[
        for (final row in students)
          if (scopeClassroom == null || row.classroomName == scopeClassroom)
            row,
      ],
      _ => staff,
    };

    final scopedNames = scopeClassroom != null
        ? <String>[scopeClassroom]
        : <String>[
            for (final name in _enrolled.keys)
              if (students.any((r) => r.classroomName == name)) name,
          ];

    return AttendanceSnapshot(
      rows: rows,
      classroomNames: scopedNames,
      enrolled: _enrolled,
      allowedRatio: _allowedRatio,
      staffPresent: _staffPresent(staff),
      schoolClassroomCount: DemoData.classroomNames.length,
      studentsTotal: students.length,
      studentsSignedIn: _countIn(students),
      staffTotal: staff.length,
      staffSignedIn: _countIn(staff),
      staffMinutesToday: _staffMinutes(staff),
      selfShift: persona == Persona.staff ? _selfShift : null,
      staffGap: !audience.isStudents && persona != Persona.guardian
          ? _staffGap
          : null,
      children: persona == Persona.guardian ? _children(students) : const [],
    );
  }

  static int _countIn(List<AttendanceRecord> rows) =>
      rows.where((r) => r.status == AttendanceStatus.signedIn).length;

  /// Staff standing in each classroom right now, which is what the group
  /// header's verdict is measured against.
  static Map<String, int> _staffPresent(List<AttendanceRecord> staff) {
    final present = <String, int>{};
    for (final name in _enrolled.keys) {
      present[name] = staff
          .where(
            (r) =>
                r.status == AttendanceStatus.signedIn &&
                r.classroomName.contains(name),
          )
          .length;
    }
    return present;
  }

  static int _staffMinutes(List<AttendanceRecord> staff) {
    final now = ClockTime.fromDateTime(DemoData.today);
    var total = 0;
    for (final row in staff) {
      final from = row.signedInTime;
      if (row.status == AttendanceStatus.signedIn && from != null) {
        total += from.minutesUntil(now);
      }
    }
    return total;
  }

  static const StaffGap _staffGap = StaffGap(
    classroomName: 'Bluebell',
    at: ClockTime(11, 30),
    body:
        'Tomas Berg signed out at 9:12 and Priya Raman is the only staff '
        'member left with six toddlers in. Priya is due a break at 11:30, '
        'and the classroom forecast puts that block at 2 required, '
        '1 scheduled.',
  );

  // --- The two rosters, as attendance rows ---------------------------------

  List<AttendanceRecord> _students() => <AttendanceRecord>[
    for (final (i, demo) in DemoData.students.indexed) _studentRow(i, demo),
  ];

  AttendanceRecord _studentRow(int index, DemoStudent demo) {
    final written = _written[demo.id];
    if (written != null) return written;

    final status = _status(demo.attendance);
    final stamped = _parseTime(demo.timeLabel);
    final method = _methodCycle[index % _methodCycle.length];
    final by = _signedInBy[demo.id] ?? _classroomLead[demo.classroom] ?? '';

    return AttendanceRecord(
      id: demo.id,
      fullName: demo.name,
      initials: demo.initials,
      audience: AttendanceAudience.students,
      status: status,
      classroomName: demo.classroom,
      isExpectedToday: !_notExpectedToday.contains(demo.id),
      signedInTime: switch (status) {
        AttendanceStatus.signedIn => stamped,
        AttendanceStatus.signedOut => _signedInAt[demo.id],
        _ => null,
      },
      signedInBy: status == AttendanceStatus.notMarked ? null : by,
      signedInMethod: switch (status) {
        AttendanceStatus.signedIn || AttendanceStatus.signedOut => method,
        _ => null,
      },
      signedOutTime: status == AttendanceStatus.signedOut ? stamped : null,
      signedOutBy: status == AttendanceStatus.signedOut ? by : null,
      signedOutMethod: status == AttendanceStatus.signedOut
          ? AttendanceMethod.app
          : null,
      absenceReason: status == AttendanceStatus.absent
          ? _absenceReasons[demo.id]
          : null,
      transfer: _transfers[demo.id],
    );
  }

  List<AttendanceRecord> _staff() => <AttendanceRecord>[
    for (final (i, demo) in DemoData.staffMembers.indexed) _staffRow(i, demo),
  ];

  AttendanceRecord _staffRow(int index, DemoStaff demo) {
    final written = _written[demo.id];
    if (written != null) return written;

    final status = _status(demo.attendance);
    final stamped = _parseTime(demo.timeLabel);
    final shift = _shiftLabels[demo.id] ?? '';

    return AttendanceRecord(
      id: demo.id,
      fullName: demo.name,
      initials: demo.initials,
      audience: AttendanceAudience.staff,
      status: status,
      classroomName: demo.scope,
      roleLabel:
          _roleOverrides[demo.id] ??
          '${demo.designation} · ${demo.scope}'
              ' · $shift',
      isExpectedToday: true,
      expectedTime: _shiftStarts[demo.id],
      signedInTime: switch (status) {
        AttendanceStatus.signedIn => stamped,
        AttendanceStatus.signedOut => _signedInAt[demo.id],
        _ => null,
      },
      signedInBy: status == AttendanceStatus.notMarked ? null : demo.name,
      signedInMethod: switch (status) {
        AttendanceStatus.signedIn ||
        AttendanceStatus.signedOut => _methodCycle[index % _methodCycle.length],
        _ => null,
      },
      signedOutTime: status == AttendanceStatus.signedOut ? stamped : null,
      signedOutBy: status == AttendanceStatus.signedOut ? demo.name : null,
      signedOutMethod: status == AttendanceStatus.signedOut
          ? AttendanceMethod.gps
          : null,
      absenceReason: status == AttendanceStatus.absent
          ? _absenceReasons[demo.id]
          : null,
      transfer: _transfers[demo.id],
    );
  }

  // --- The guardian lens ----------------------------------------------------

  static List<AttendanceRecord> _guardianRows(List<AttendanceRecord> all) {
    final mine = DemoData.guardianChildren.map((s) => s.id).toSet();
    return <AttendanceRecord>[
      for (final row in all)
        if (mine.contains(row.id)) row,
    ];
  }

  static List<GuardianChildAttendance> _children(
    List<AttendanceRecord> students,
  ) => <GuardianChildAttendance>[
    for (final (i, row) in _guardianRows(students).indexed)
      GuardianChildAttendance(
        today: row,
        days: _guardianDays(row),
        daysIn: 13 - i,
        daysAbsent: i == 0 ? 1 : 0,
        hours: 91 - i * 13,
      ),
  ];

  /// Today, then the four days behind it. The past days are the same shape
  /// for every child, with their own name written into them.
  static List<GuardianDay> _guardianDays(AttendanceRecord row) {
    final name = row.firstName;
    return <GuardianDay>[
      GuardianDay(
        dateLabel: AttendanceFormats.dayLabel(DemoData.today, DemoData.today),
        detail: _guardianTodayLine(row),
        trailing: _guardianTodayTrailing(row),
        status: row.status,
      ),
      GuardianDay(
        dateLabel: 'Wed 19 Aug',
        detail: '8:35 to 3:40 · you collected $name',
        trailing: '7h 5m',
        status: AttendanceStatus.signedOut,
      ),
      GuardianDay(
        dateLabel: 'Tue 18 Aug',
        detail: 'You marked $name absent at 7:10',
        trailing: 'Absent',
        status: AttendanceStatus.absent,
      ),
      GuardianDay(
        dateLabel: 'Mon 17 Aug',
        detail: '8:20 to 4:05 · grandma collected $name',
        trailing: '7h 45m',
        status: AttendanceStatus.signedOut,
      ),
      GuardianDay(
        dateLabel: 'Fri 14 Aug',
        detail: '8:30 to 3:30 · you collected $name',
        trailing: '7h',
        status: AttendanceStatus.signedOut,
      ),
    ];
  }

  static String _guardianTodayLine(AttendanceRecord row) {
    final inAt = row.signedInTime;
    final outAt = row.signedOutTime;
    if (outAt != null && inAt != null) {
      return '${inAt.label} to ${outAt.label} · '
          '${row.signedOutBy ?? ''} signed ${row.firstName} out';
    }
    if (inAt != null) {
      return 'In ${inAt.label} · at the door, by ${row.signedInBy ?? ''}';
    }
    if (row.isAbsent) return row.absenceReason ?? '';
    return 'Nothing recorded yet today';
  }

  static String _guardianTodayTrailing(AttendanceRecord row) {
    final inAt = row.signedInTime;
    final outAt = row.signedOutTime;
    if (inAt != null && outAt != null) {
      return AttendanceFormats.between(inAt, outAt);
    }
    if (row.isSignedIn) return 'In now';
    if (row.isAbsent) return 'Absent';
    return 'Not Marked';
  }

  // --- The range ------------------------------------------------------------

  @override
  Future<List<String>> classroomNames() async {
    await Future<void>.delayed(_writeLatency);
    return DemoData.classroomNames;
  }

  @override
  Future<RangePage> loadRange({
    required AttendanceAudience audience,
    required DateRange range,
    Set<String> classrooms = const <String>{},
    String query = '',
    int page = 0,
  }) async {
    await Future<void>.delayed(_latency);

    final term = query.trim().toLowerCase();
    final all = <RangeEntry>[
      for (final (i, entry) in _rangeEntries(audience).indexed)
        if (_matchesRange(entry, term, classrooms)) _withTotals(entry, i),
    ];

    final start = page * _rangePageSize;
    final end = (start + _rangePageSize).clamp(0, all.length);
    return RangePage(
      entries: start >= all.length ? const [] : all.sublist(start, end),
      page: page,
      totalElements: all.length,
      hasMore: end < all.length,
    );
  }

  static bool _matchesRange(
    RangeEntry entry,
    String term,
    Set<String> classrooms,
  ) {
    if (term.isNotEmpty && !entry.fullName.toLowerCase().contains(term)) {
      return false;
    }
    if (classrooms.isEmpty) return true;
    return classrooms.any(entry.classroomName.contains);
  }

  static List<RangeEntry> _rangeEntries(AttendanceAudience audience) =>
      audience.isStudents
      ? <RangeEntry>[
          for (final demo in DemoData.students)
            RangeEntry(
              id: demo.id,
              fullName: demo.name,
              initials: demo.initials,
              classroomName: demo.classroom,
              audience: AttendanceAudience.students,
              attendedHours: 0,
              attendedMinutes: 0,
              attendedDays: 0,
            ),
        ]
      : <RangeEntry>[
          for (final demo in DemoData.staffMembers)
            RangeEntry(
              id: demo.id,
              fullName: demo.name,
              initials: demo.initials,
              classroomName: demo.scope,
              audience: AttendanceAudience.staff,
              attendedHours: 0,
              attendedMinutes: 0,
              attendedDays: 0,
            ),
        ];

  /// The totals the range call returns. Dana's are the frame's own; the rest
  /// are worked out from the position in the list so the page is stable
  /// between loads.
  static RangeEntry _withTotals(RangeEntry entry, int index) {
    final fixed = _rangeTotals[entry.id];
    final days = fixed?.$3 ?? 16 - index % 6;
    return RangeEntry(
      id: entry.id,
      fullName: entry.fullName,
      initials: entry.initials,
      classroomName: entry.classroomName,
      audience: entry.audience,
      attendedHours: fixed?.$1 ?? days * 8 - index % 5,
      attendedMinutes: fixed?.$2 ?? index * 7 % 60,
      attendedDays: days,
    );
  }

  static const Map<String, (int, int, int)> _rangeTotals =
      <String, (int, int, int)>{
        'dana': (128, 40, 16),
        'priya': (119, 20, 15),
        'marcus': (134, 10, 17),
        'tomas': (64, 15, 8),
        'aisha': (72, 0, 9),
      };

  // --- Writes ---------------------------------------------------------------

  @override
  Future<bool> isInsideGeofence() async {
    await Future<void>.delayed(_writeLatency);
    return _selfShift.isInsideGeofence;
  }

  @override
  Future<SelfShift> signSelfIn() async {
    await Future<void>.delayed(_writeLatency);
    _selfShift = _selfShift.copyWith(signedInAt: const ClockTime(7, 48));
    return _selfShift;
  }

  @override
  Future<SelfShift> signSelfOut() async {
    await Future<void>.delayed(_writeLatency);
    _selfShift = _selfShift.copyWith(
      signedOutAt: ClockTime.fromDateTime(DemoData.today),
    );
    return _selfShift;
  }

  @override
  Future<void> signIn({
    required List<String> ids,
    required AttendanceAudience audience,
    required DateTime at,
  }) async {
    await Future<void>.delayed(_writeLatency);
    final time = ClockTime.fromDateTime(at);
    for (final id in ids) {
      final row = _find(id, audience);
      if (row == null) continue;
      _written[id] = _copy(
        row,
        status: AttendanceStatus.signedIn,
        signedInTime: time,
        signedInBy: _actorName,
        signedInMethod: AttendanceMethod.app,
        clearSignedOut: true,
        clearAbsence: true,
      );
    }
  }

  @override
  Future<void> signOut({
    required List<String> ids,
    required AttendanceAudience audience,
    required DateTime at,
  }) async {
    await Future<void>.delayed(_writeLatency);
    final time = ClockTime.fromDateTime(at);
    for (final id in ids) {
      final row = _find(id, audience);
      if (row == null) continue;
      _written[id] = _copy(
        row,
        status: AttendanceStatus.signedOut,
        signedOutTime: time,
        signedOutBy: _actorName,
        signedOutMethod: AttendanceMethod.app,
      );
    }
  }

  @override
  Future<void> markAbsent({
    required List<String> ids,
    required DateTime date,
    required String reason,
  }) async {
    await Future<void>.delayed(_writeLatency);
    for (final id in ids) {
      final row =
          _find(id, AttendanceAudience.students) ??
          _find(id, AttendanceAudience.staff);
      if (row == null) continue;
      _written[id] = _copy(
        row,
        status: AttendanceStatus.absent,
        absenceReason: reason,
        clearSignedIn: true,
        clearSignedOut: true,
      );
    }
  }

  @override
  Future<void> undoAbsence(String id) async {
    await Future<void>.delayed(_writeLatency);
    final row =
        _find(id, AttendanceAudience.students) ??
        _find(id, AttendanceAudience.staff);
    if (row == null) return;
    _written[id] = _copy(
      row,
      status: AttendanceStatus.notMarked,
      clearAbsence: true,
      clearSignedIn: true,
      clearSignedOut: true,
    );
  }

  @override
  Future<void> transfer({
    required String id,
    required String toClassroom,
  }) async {
    await Future<void>.delayed(_writeLatency);
    final row =
        _find(id, AttendanceAudience.students) ??
        _find(id, AttendanceAudience.staff);
    if (row == null) return;
    final at = ClockTime.fromDateTime(DemoData.today);
    _written[id] = _copy(
      row,
      classroomName: toClassroom,
      transfer: TransferTrail(
        fromClassroom: row.classroomName,
        toClassroom: toClassroom,
        sequenceNumber: (row.transfer?.sequenceNumber ?? 1) + 1,
        totalSequenceCount: (row.transfer?.totalSequenceCount ?? 1) + 1,
        transferTime: at,
        transferredBy: _actorName,
        reason: 'Moved from the attendance list',
      ),
    );
  }

  @override
  Future<void> editTimes({
    required String id,
    required DateTime at,
    required bool isSignOut,
  }) async {
    await Future<void>.delayed(_writeLatency);
    final row =
        _find(id, AttendanceAudience.students) ??
        _find(id, AttendanceAudience.staff);
    if (row == null) return;
    final time = ClockTime.fromDateTime(at);
    _written[id] = _copy(
      row,
      signedInTime: isSignOut ? null : time,
      signedOutTime: isSignOut ? time : null,
    );
  }

  /// Whoever is holding the device. `signedInBy` and `signedOutBy` are never
  /// typed: the API takes them from the staff or guardian code on the call.
  static const String _actorName = 'Dana Whitfield';

  AttendanceRecord? _find(String id, AttendanceAudience audience) {
    final rows = audience.isStudents ? _students() : _staff();
    for (final row in rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  static AttendanceRecord _copy(
    AttendanceRecord row, {
    AttendanceStatus? status,
    String? classroomName,
    ClockTime? signedInTime,
    String? signedInBy,
    AttendanceMethod? signedInMethod,
    ClockTime? signedOutTime,
    String? signedOutBy,
    AttendanceMethod? signedOutMethod,
    String? absenceReason,
    TransferTrail? transfer,
    bool clearSignedIn = false,
    bool clearSignedOut = false,
    bool clearAbsence = false,
  }) => AttendanceRecord(
    id: row.id,
    fullName: row.fullName,
    initials: row.initials,
    audience: row.audience,
    status: status ?? row.status,
    classroomName: classroomName ?? row.classroomName,
    roleLabel: row.roleLabel,
    isExpectedToday: row.isExpectedToday,
    expectedTime: row.expectedTime,
    signedInTime: clearSignedIn ? null : signedInTime ?? row.signedInTime,
    signedInBy: clearSignedIn ? null : signedInBy ?? row.signedInBy,
    signedInMethod: clearSignedIn ? null : signedInMethod ?? row.signedInMethod,
    signedOutTime: clearSignedOut ? null : signedOutTime ?? row.signedOutTime,
    signedOutBy: clearSignedOut ? null : signedOutBy ?? row.signedOutBy,
    signedOutMethod: clearSignedOut
        ? null
        : signedOutMethod ?? row.signedOutMethod,
    absenceReason: clearAbsence ? null : absenceReason ?? row.absenceReason,
    transfer: transfer ?? row.transfer,
  );

  // --- Fixture tables -------------------------------------------------------

  static AttendanceStatus _status(DemoAttendance attendance) =>
      switch (attendance) {
        DemoAttendance.signedIn => AttendanceStatus.signedIn,
        DemoAttendance.signedOut => AttendanceStatus.signedOut,
        DemoAttendance.absent => AttendanceStatus.absent,
        DemoAttendance.notMarked => AttendanceStatus.notMarked,
      };

  /// Pulls "8:12 AM" out of a demo label, whatever else is written round it.
  static ClockTime? _parseTime(String label) {
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isAfternoon = match.group(3)!.toUpperCase() == 'PM';
    if (isAfternoon && hour != 12) hour += 12;
    if (!isAfternoon && hour == 12) hour = 0;
    return ClockTime(hour, minute);
  }

  /// The four methods the API returns, cycled so every one of them is on
  /// screen somewhere.
  static const List<AttendanceMethod> _methodCycle = <AttendanceMethod>[
    AttendanceMethod.pin,
    AttendanceMethod.app,
    AttendanceMethod.gps,
    AttendanceMethod.pin,
    AttendanceMethod.qr,
  ];

  static const Map<String, String> _classroomLead = <String, String>{
    'Sunflower': 'Dana Whitfield',
    'Bluebell': 'Priya Raman',
  };

  static const Map<String, String> _signedInBy = <String, String>{
    'theo': 'Marcus Whitfield',
    'sam': 'Marcus Whitfield',
    'ada': 'Marcus Whitfield',
  };

  /// The one field the daily row holds that no screen has ever drawn.
  static const Set<String> _notExpectedToday = <String>{'elias', 'sena'};

  /// A signed-out row needs the time it started, which the demo label does
  /// not carry: it holds the sign-out.
  static const Map<String, ClockTime> _signedInAt = <String, ClockTime>{
    'sam': ClockTime(8, 6),
    'tomas': ClockTime(7, 5),
  };

  static const Map<String, String> _absenceReasons = <String, String>{
    'lila': 'Sick, dad called 7:55',
    'felix': 'Family holiday, booked 4 Aug',
    'aisha': 'Sick, called 6:58',
  };

  /// The full trail: from and to, which stint of the day this is, when the
  /// next one is due, who moved them and why.
  static const Map<String, TransferTrail> _transfers = <String, TransferTrail>{
    'omar': TransferTrail(
      fromClassroom: 'Sunflower',
      toClassroom: 'Acorn',
      sequenceNumber: 1,
      totalSequenceCount: 2,
      transferTime: ClockTime(9, 30),
      nextActionTime: ClockTime(11, 30),
      transferredBy: 'Dana Whitfield',
      reason: 'Outdoor play with Acorn',
    ),
    'hugo': TransferTrail(
      fromClassroom: 'Acorn',
      toClassroom: 'Bluebell',
      sequenceNumber: 2,
      totalSequenceCount: 2,
      transferTime: ClockTime(9, 15),
      transferredBy: 'Marcus Whitfield',
      reason: 'Covering Tomas until noon',
    ),
  };

  static const Map<String, String> _shiftLabels = <String, String>{
    'marcus': '7:30 to 4:30',
    'dana': '8:00 to 4:00',
    'priya': '8:30 to 5:00',
    'ruth': '7:30 to 3:30',
    'hugo': '7:45 to 4:15',
    'grace': '6:30 to 2:30',
    'noor': '8:00 to 4:00',
    'jamal': '12:00 to 6:00',
    'tomas': '7:00 to 3:00',
    'aisha': '8:00 to 4:00',
  };

  static const Map<String, ClockTime> _shiftStarts = <String, ClockTime>{
    'marcus': ClockTime(7, 30),
    'dana': ClockTime(8, 0),
    'priya': ClockTime(8, 30),
    'ruth': ClockTime(7, 30),
    'hugo': ClockTime(7, 45),
    'grace': ClockTime(6, 30),
    'noor': ClockTime(8, 0),
    'jamal': ClockTime(12, 0),
    'tomas': ClockTime(7, 0),
    'aisha': ClockTime(8, 0),
  };

  /// The director is on the floor and is not counted in ratio, which the
  /// staff list says out loud rather than leaving to be inferred.
  static const Map<String, String> _roleOverrides = <String, String>{
    'marcus': 'Director · not counted in ratio · 7:30 to 4:30',
  };
}
