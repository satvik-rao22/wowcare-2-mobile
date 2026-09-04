import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';

/// M07's fixtures: Maple View's five classrooms on the design's own day.
///
/// The five names are `DemoData.classroomNames`, Sunflower and Bluebell carry
/// the demo school's own rosters, and every staff member is somebody the rest
/// of the app already knows. The per-classroom figures are the frames' own,
/// and the school-level figures on the navy card are the frames' too: they
/// come from separate capacity, FTE and attendance-summary readings rather
/// than from summing the list, which is how the real screen gets them.
///
/// Ratio is never a stored figure. Every classroom carries `allowedRatio` and
/// the model does the arithmetic, so the pill says In Ratio or how many more
/// staff are wanted and nothing anywhere says `9:1`.
class PreviewClassroomsSource implements ClassroomsSource {
  const PreviewClassroomsSource();

  static const Duration _latency = Duration(milliseconds: 450);
  static const Duration _writeLatency = Duration(milliseconds: 350);

  // --- The floor -------------------------------------------------------------

  static const String sunflowerId = 'sunflower';
  static const String bluebellId = 'bluebell';
  static const String acornId = 'acorn';
  static const String willowId = 'willow';
  static const String mapleId = 'maple';

  /// The four students at the school who belong to no classroom (7j's copy).
  static const int _unassignedStudents = 4;

  static List<ClassroomSummary> get _classrooms => <ClassroomSummary>[
    ClassroomSummary(
      id: sunflowerId,
      name: DemoData.classroomNames[0],
      ageBand: ClassroomsStrings.ageBand('2', '3 yrs'),
      enrolled: 23,
      capacity: 26,
      studentsPresent: 14,
      staffPresent: 3,
      allowedRatio: 8,
      minAgeMonths: 24,
      maxAgeMonths: 35,
      leadName: DemoData.staffMembers[1].name,
      leadInitials: DemoData.staffMembers[1].initials,
      startingSoon: 3,
    ),
    ClassroomSummary(
      id: bluebellId,
      name: DemoData.classroomNames[1],
      ageBand: ClassroomsStrings.ageBand('3', '4 yrs'),
      enrolled: 21,
      capacity: 22,
      studentsPresent: 19,
      staffPresent: 2,
      allowedRatio: 8,
      minAgeMonths: 36,
      maxAgeMonths: 47,
      leadName: DemoData.staffMembers[2].name,
      leadInitials: DemoData.staffMembers[2].initials,
      startingSoon: 1,
    ),
    ClassroomSummary(
      id: acornId,
      name: DemoData.classroomNames[2],
      ageBand: ClassroomsStrings.ageBand('6', '18 mo'),
      enrolled: 8,
      capacity: 10,
      studentsPresent: 6,
      staffPresent: 3,
      allowedRatio: 3,
      minAgeMonths: 6,
      maxAgeMonths: 18,
      leadName: DemoData.staffMembers[3].name,
      leadInitials: DemoData.staffMembers[3].initials,
    ),
    ClassroomSummary(
      id: willowId,
      name: DemoData.classroomNames[3],
      ageBand: ClassroomsStrings.ageBand('2', '3 yrs'),
      enrolled: 0,
      capacity: 12,
      studentsPresent: 0,
      staffPresent: 0,
      allowedRatio: 8,
      minAgeMonths: 24,
      maxAgeMonths: 35,
    ),
    ClassroomSummary(
      id: mapleId,
      name: DemoData.classroomNames[4],
      ageBand: ClassroomsStrings.ageBand('4', '5 yrs'),
      enrolled: 14,
      capacity: 14,
      studentsPresent: 0,
      staffPresent: 0,
      allowedRatio: 10,
      minAgeMonths: 48,
      maxAgeMonths: 71,
    ),
  ];

  static ClassroomSummary _summary(String id) => _classrooms.firstWhere(
    (r) => r.id == id,
    orElse: () => _classrooms.first,
  );

  @override
  Future<ClassroomBoard> loadBoard() async {
    await Future<void>.delayed(_latency);
    return ClassroomBoard(
      date: DemoData.today,
      studentsPresent: 47,
      staffOnDuty: 12,
      enrolled: 78,
      places: 96,
      classrooms: _classrooms,
      unassignedStudents: _unassignedStudents,
    );
  }

  // --- One classroom ---------------------------------------------------------

  @override
  Future<ClassroomDetail> loadClassroom(String id) async {
    await Future<void>.delayed(_latency);
    final summary = _summary(id);
    final students = _rosterFor(id);
    final staff = _staffFor(id);

    return ClassroomDetail(
      summary: summary,
      students: students,
      staff: staff,
      notes: id == sunflowerId ? _sunflowerNotes : const <ClassroomNote>[],
      newNoteCount: id == sunflowerId ? 2 : 0,
      careTags: <String>{
        for (final student in students)
          for (final tag in student.careNeeds) tag.label,
      }.toList(),
      designations: <String>{
        for (final person in staff) person.designation,
      }.toList(),
      others: <ClassroomSummary>[
        for (final classroom in _classrooms)
          if (classroom.id != id) classroom,
      ],
    );
  }

  /// Sunflower and Bluebell carry the demo school's own rosters. The other
  /// three are the frames' counts only: the design draws them on the list and
  /// never opens them.
  static List<RosterStudent> _rosterFor(String id) => switch (id) {
    sunflowerId => <RosterStudent>[
      for (final (i, student) in DemoData.sunflower.indexed)
        _toRosterStudent(student, i),
    ],
    bluebellId => <RosterStudent>[
      for (final (i, student) in DemoData.bluebell.indexed)
        _toRosterStudent(student, i),
    ],
    _ => const <RosterStudent>[],
  };

  static RosterStudent _toRosterStudent(DemoStudent student, int index) {
    final hasAllergy = student.allergy != ClassroomsStrings.noCareNeeds;
    final isHalfDay = student.tag.contains('Half day');
    final isNapping = _nappingIds.contains(student.id);

    final tags = <RosterTag>[
      if (hasAllergy)
        RosterTag(label: student.allergy, tone: RosterTone.danger),
      for (final label in student.tag.split(' · '))
        if (label.isNotEmpty) RosterTag(label: label),
    ];

    return RosterStudent(
      id: student.id,
      name: student.name,
      initials: student.initials,
      age: _readableAge(student.age),
      attendance: _toAttendance(student.attendance),
      timeLabel: student.timeLabel,
      flag: hasAllergy
          ? student.allergy
          : (isNapping ? ClassroomsStrings.napping : null),
      flagTone: hasAllergy ? RosterTone.danger : RosterTone.neutral,
      careNeeds: tags,
      weekdays: _weekPatterns[index % _weekPatterns.length],
      hours: isHalfDay ? '8:00 to 12:00' : '7:30 to 17:30',
      guardianName: student.guardianName,
      moveNote: _moves[student.id],
      isNapping: isNapping,
    );
  }

  static const Set<String> _nappingIds = <String>{'theo', 'wren'};

  /// A planned move already booked in Movements. Read-only here: this module
  /// never books one, which is what the costly list rules out.
  static const Map<String, String> _moves = <String, String>{
    'amara': 'Moves to Bluebell on 1 Sep',
    'ada': 'Moves to Sunflower on 1 Sep',
  };

  static const List<List<bool>> _weekPatterns = <List<bool>>[
    <bool>[true, true, true, true, true],
    <bool>[true, true, false, true, true],
    <bool>[true, false, true, false, true],
    <bool>[true, true, true, true, false],
    <bool>[false, true, true, true, true],
  ];

  // --- Staff -----------------------------------------------------------------

  static List<ClassroomStaffMember> _staffFor(String id) => switch (id) {
    sunflowerId => <ClassroomStaffMember>[
      _staff('dana', StaffDutyState.onDuty, 'In 7:48 · 4h 38m worked'),
      _staff('marcus', StaffDutyState.onDuty, 'In 7:34 · 5h 12m worked'),
      _staff('hugo', StaffDutyState.onBreak, 'In 7:55 · break 22m'),
      _staff('aisha', StaffDutyState.absent, 'Marked 6:58 AM'),
    ],
    bluebellId => <ClassroomStaffMember>[
      _staff('priya', StaffDutyState.onDuty, 'In 7:52 · 4h 30m worked'),
      _staff('jamal', StaffDutyState.onDuty, 'In 8:26 · 2h 04m worked'),
      _staff('tomas', StaffDutyState.signedOut, 'Out 9:12 · 1h 48m worked'),
    ],
    acornId => <ClassroomStaffMember>[
      _staff('ruth', StaffDutyState.onDuty, 'In 7:41 · 4h 45m worked'),
      _staff('marcus', StaffDutyState.onDuty, 'In 7:34 · 5h 12m worked'),
      _staff('noor', StaffDutyState.onDuty, 'In 8:05 · 3h 20m worked'),
    ],
    _ => const <ClassroomStaffMember>[],
  };

  static ClassroomStaffMember _staff(
    String id,
    StaffDutyState state,
    String times,
  ) {
    final person = DemoData.staffMembers.firstWhere((s) => s.id == id);
    return ClassroomStaffMember(
      id: person.id,
      name: person.name,
      initials: person.initials,
      designation: person.designation,
      state: state,
      timesLabel: times,
      classroomsLabel: person.scope,
    );
  }

  // --- Notes -----------------------------------------------------------------

  static List<ClassroomNote> get _sunflowerNotes => <ClassroomNote>[
    ClassroomNote(
      id: 'n1',
      author: DemoData.staffMembers[1].name,
      initials: DemoData.staffMembers[1].initials,
      timeLabel: '8:20',
      text: 'Theo’s inhaler is in the red bag today, not the cupboard.',
    ),
    ClassroomNote(
      id: 'n2',
      author: DemoData.staffMembers[4].name,
      initials: DemoData.staffMembers[4].initials,
      timeLabel: '9:05',
      text: 'Water table is outside until 11. Sun cream done for everyone in.',
    ),
    const ClassroomNote(
      id: 'n3',
      author: ClassroomsStrings.you,
      initials: 'ME',
      timeLabel: '11:40',
      text:
          'Hazel is Not Marked and the family has not called. I will try again '
          'at 12.',
      isMine: true,
    ),
    ClassroomNote(
      id: 'n4',
      author: DemoData.staffMembers[2].name,
      initials: DemoData.staffMembers[2].initials,
      timeLabel: '12:41',
      text: 'Theo went down for a nap at 12:40.',
      isFirstUnread: true,
    ),
    ClassroomNote(
      id: 'n5',
      author: DemoData.staffMembers[1].name,
      initials: DemoData.staffMembers[1].initials,
      timeLabel: '12:58',
      text: 'Lunch counts for tomorrow: 12 hot, 2 packed.',
    ),
  ];

  @override
  Future<ClassroomNote> postNote({
    required String classroomId,
    required String text,
  }) async {
    await Future<void>.delayed(_writeLatency);
    return ClassroomNote(
      id: 'n${DateTime.now().microsecondsSinceEpoch}',
      author: ClassroomsStrings.you,
      initials: 'ME',
      timeLabel: '13:04',
      text: text,
      isMine: true,
    );
  }

  // --- The classroom's own record --------------------------------------------

  @override
  Future<ClassroomProfile> loadProfile(String id) async {
    await Future<void>.delayed(_latency);
    final summary = _summary(id);
    final staff = _staffFor(id);

    return ClassroomProfile(
      summary: summary,
      students: _studentDay(summary),
      staff: DayBreakdown(
        signedIn: staff.where((p) => p.isPresent).length,
        notMarked: staff
            .where((p) => p.state == StaffDutyState.notMarked)
            .length,
        absent: staff.where((p) => p.state == StaffDutyState.absent).length,
        signedOut: staff
            .where((p) => p.state == StaffDutyState.signedOut)
            .length,
      ),
      movements: id == sunflowerId
          ? _sunflowerMovements
          : const <ClassroomMovement>[],
      center: CenterSummary(
        classroomCount: _classrooms.length,
        totalPlaces: 96,
        fullTimeEquivalent: 62.4,
        rows: <CenterRatioRow>[
          for (final classroom in _classrooms)
            CenterRatioRow(
              name: classroom.name,
              studentsPresent: classroom.studentsPresent,
              staffPresent: classroom.staffPresent,
              state: classroom.ratioState,
              staffNeeded: classroom.staffNeeded,
            ),
        ],
      ),
    );
  }

  /// Today's four states for a classroom's roll. Absences and sign-outs are
  /// the frame's own for Sunflower; every other classroom splits its roll
  /// between the students who are in and the ones still Not Marked.
  static DayBreakdown _studentDay(ClassroomSummary summary) {
    if (summary.id == sunflowerId) {
      return const DayBreakdown(
        signedIn: 14,
        notMarked: 5,
        absent: 3,
        signedOut: 1,
      );
    }
    return DayBreakdown(
      signedIn: summary.studentsPresent,
      notMarked: summary.enrolled - summary.studentsPresent,
    );
  }

  static List<ClassroomMovement> get _sunflowerMovements => <ClassroomMovement>[
    const ClassroomMovement(
      name: 'Ivy Chen',
      detail: 'From Acorn on 1 Sep',
      isArriving: true,
    ),
    const ClassroomMovement(
      name: 'Sena Adjei',
      detail: 'New enrollment, starts 8 Sep',
      isArriving: true,
    ),
    const ClassroomMovement(
      name: 'Amara Okafor',
      detail: 'To Bluebell on 1 Sep',
      isArriving: false,
    ),
  ];

  @override
  Future<ClassroomPhoto> uploadPhoto({
    required String classroomId,
    required String fileName,
  }) async {
    await Future<void>.delayed(_latency);
    return ClassroomPhoto(fileName: fileName);
  }

  @override
  Future<void> removePhoto(String classroomId) =>
      Future<void>.delayed(_writeLatency);

  // --- Assigning -------------------------------------------------------------

  @override
  Future<List<AssignCandidate>> loadCandidates({
    required String classroomId,
    required AssignKind kind,
  }) async {
    await Future<void>.delayed(_latency);
    return kind == AssignKind.students
        ? _studentCandidates(classroomId)
        : _staffCandidates(classroomId);
  }

  /// Everybody at the school who is not already on this classroom's roster.
  /// A student who has not been marked today and belongs nowhere reads as
  /// Unassigned, which is the chip the frame leads with.
  static List<AssignCandidate> _studentCandidates(String classroomId) {
    final summary = _summary(classroomId);
    final here = _rosterFor(classroomId).map((s) => s.id).toSet();

    return <AssignCandidate>[
      for (final student in DemoData.students)
        if (!here.contains(student.id))
          AssignCandidate(
            id: student.id,
            name: student.name,
            initials: student.initials,
            group: student.attendance == DemoAttendance.notMarked
                ? ClassroomsStrings.unassigned
                : student.classroom,
            age: _readableAge(student.age),
            isOutsideAgeRange: summary.isAgeOutsideRange(
              _ageInMonths(student.age),
            ),
          ),
    ];
  }

  static List<AssignCandidate> _staffCandidates(String classroomId) {
    final summary = _summary(classroomId);
    final here = _staffFor(classroomId).map((p) => p.id).toSet();

    return <AssignCandidate>[
      for (final person in DemoData.staffMembers)
        if (!here.contains(person.id))
          AssignCandidate(
            id: person.id,
            name: person.name,
            initials: person.initials,
            group: summary.name,
            designation: person.designation,
            note: ClassroomsStrings.alreadyIn(person.scope),
          ),
    ];
  }

  @override
  Future<void> assign({
    required String classroomId,
    required AssignKind kind,
    required List<String> ids,
  }) => Future<void>.delayed(_writeLatency);

  @override
  Future<void> removeStudent({
    required String classroomId,
    required String studentId,
  }) => Future<void>.delayed(_writeLatency);

  @override
  Future<void> moveStudent({
    required String fromClassroomId,
    required String toClassroomId,
    required String studentId,
  }) => Future<void>.delayed(_writeLatency);

  @override
  Future<ClassroomSummary> createClassroom(ClassroomDraft draft) async {
    await Future<void>.delayed(_writeLatency);
    return ClassroomSummary(
      id: draft.name.trim().toLowerCase().replaceAll(' ', '-'),
      name: draft.name.trim(),
      ageBand: _bandLabel(draft.ageFromMonths, draft.ageToMonths),
      enrolled: 0,
      capacity: draft.capacity ?? 0,
      studentsPresent: 0,
      staffPresent: 0,
      allowedRatio: draft.studentsPerStaff ?? 0,
      minAgeMonths: draft.ageFromMonths ?? 0,
      maxAgeMonths: draft.ageToMonths ?? 0,
    );
  }

  // --- Small conversions -----------------------------------------------------

  static AttendanceStatus _toAttendance(DemoAttendance attendance) =>
      switch (attendance) {
        DemoAttendance.signedIn => AttendanceStatus.signedIn,
        DemoAttendance.signedOut => AttendanceStatus.signedOut,
        DemoAttendance.absent => AttendanceStatus.absent,
        DemoAttendance.notMarked => AttendanceStatus.notMarked,
      };

  /// `DemoData` writes an age as `4y 2m`; the frames read it out as
  /// `4 yrs 2 mo`.
  static String _readableAge(String age) {
    final months = _ageInMonths(age);
    final years = months ~/ 12;
    final rest = months % 12;
    if (years == 0) return ClassroomsStrings.months(rest);
    if (rest == 0) return ClassroomsStrings.years(years);
    return '${ClassroomsStrings.years(years)} ${ClassroomsStrings.months(rest)}';
  }

  static int _ageInMonths(String age) {
    var months = 0;
    for (final part in age.split(' ')) {
      final value = int.tryParse(part.replaceAll(RegExp('[a-z]'), '')) ?? 0;
      months += part.endsWith('y') ? value * 12 : value;
    }
    return months;
  }

  static String _bandLabel(int? from, int? to) {
    if (from == null && to == null) return ClassroomsStrings.noAgeLimit;
    if (to == null) return ClassroomsStrings.ageFrom(_readableMonths(from!));
    if (from == null) return ClassroomsStrings.ageUpTo(_readableMonths(to));
    return ClassroomsStrings.ageBand('$from', _readableMonths(to));
  }

  static String _readableMonths(int months) => months >= 12 && months % 12 == 0
      ? ClassroomsStrings.years(months ~/ 12)
      : ClassroomsStrings.months(months);
}
