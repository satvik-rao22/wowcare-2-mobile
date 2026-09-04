import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';
import 'package:wowcare/redesign/features/students/students_formats.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// M05's fixtures: Maple View's 23 active students on the design's own day.
///
/// The people are `DemoData`'s, so the Sunflower roster opened from More is
/// the same Sunflower the dashboard counts and the kiosk signs in. What the
/// frames add on top of a roster row (immunization dates, documents,
/// emergency contacts, pickups) is written here, because it belongs to this
/// module and nowhere else.
///
/// Two literals reach 5g's states without unplugging anything, the way
/// `PreviewAuthSource` reaches 1a's:
///
/// * searching **`offline`** returns the saved-on-this-phone roster;
/// * searching **`empty`** returns a school with no students yet.
///
/// A guardian is refused outright, which is the module's own rule: parents
/// never reach the roster.
class PreviewStudentsSource implements StudentsSource {
  PreviewStudentsSource();

  /// Long enough that the loading ring is seen, short enough to stay out of
  /// the way.
  static const Duration _latency = Duration(milliseconds: 400);

  /// One tick of the fake upload, twenty of which make a whole file.
  static const Duration _uploadTick = Duration(milliseconds: 90);
  static const int _uploadTicks = 20;

  /// The search terms that stand in for a dead network and a new school.
  static const String _offlineQuery = 'offline';
  static const String _emptyQuery = 'empty';

  /// Uploads fail on every other attempt, so 5f's Failed and its Retry are
  /// both reachable. Nothing else in the app counts calls.
  int _uploadCall = 0;

  // --- Roster ---------------------------------------------------------------

  @override
  Future<RosterResult> loadRoster({
    required Persona persona,
    String? scopeClassroom,
    String query = '',
  }) async {
    await Future<void>.delayed(_latency);

    if (persona == Persona.guardian) return const RosterRestricted();

    final term = query.trim().toLowerCase();
    if (term == _emptyQuery) {
      return RosterLoaded(
        RosterSnapshot(
          classroomNames: _classroomNames,
          tagNames: _tagNames,
          guardianNames: _guardianNames,
        ),
      );
    }

    final snapshot = _snapshot(scope: scopeClassroom);
    if (term == _offlineQuery) {
      return RosterOffline(snapshot: snapshot, asOfLabel: '8:12 this morning');
    }
    return RosterLoaded(snapshot);
  }

  RosterSnapshot _snapshot({String? scope}) {
    final students = <StudentSummary>[
      for (final demo in DemoData.students)
        if (scope == null || demo.classroom == scope) _summary(demo),
    ];
    final upcoming = <StudentSummary>[
      for (final row in _upcoming)
        if (scope == null || row.classroomName == scope) row,
    ];

    return RosterSnapshot(
      students: students,
      upcoming: upcoming,
      classroomNames: scope == null ? _classroomNames : <String>[scope],
      tagNames: _tagNames,
      guardianNames: <String>[
        for (final name in _guardianNames)
          if (students.any((s) => s.guardianNames.contains(name))) name,
      ],
    );
  }

  /// The two rosters `DemoData` holds, turned into roster rows.
  ///
  /// Age comes off the date of birth rather than the demo string, so the
  /// roster and the profile agree to the month.
  StudentSummary _summary(DemoStudent demo) {
    final dob = _birthDates[demo.id] ?? DemoData.today;
    return StudentSummary(
      id: demo.id,
      firstName: demo.firstName,
      lastName: demo.name.split(' ').last,
      initials: demo.initials,
      classroomName: demo.classroom,
      status: StudentStatus.active,
      dateOfBirth: dob,
      age: StudentsFormats.age(dob, DemoData.today),
      attendance: _attendanceOf(demo),
      attendanceTimeLabel: _timeOf(demo),
      tags: _tagsOf(demo),
      weekdays: _weekdaysOf(demo),
      scheduleLabel: _scheduleOf(demo),
      movementLabel: _movements[demo.id],
      hasGuardian: !_withoutGuardian.contains(demo.id),
      guardianNames: <String>[demo.guardianName],
    );
  }

  static AttendanceStatus _attendanceOf(DemoStudent demo) =>
      switch (demo.attendance) {
        DemoAttendance.signedIn => AttendanceStatus.signedIn,
        DemoAttendance.signedOut => AttendanceStatus.signedOut,
        DemoAttendance.absent => AttendanceStatus.absent,
        DemoAttendance.notMarked => AttendanceStatus.notMarked,
      };

  /// `DemoData` writes the time three ways: "8:12 AM", "Marked 7:55 AM" and
  /// "expected today". Only a clock reading belongs beside the status word.
  static String? _timeOf(DemoStudent demo) {
    final label = demo.timeLabel;
    if (label.contains(':')) return label.replaceFirst('Marked ', '');
    return null;
  }

  /// A tag list per student, built from the demo world's own tag and allergy
  /// so the roster, the filter sheet and the profile all agree.
  static List<StudentTag> _tagsOf(DemoStudent demo) => <StudentTag>[
    ..._allergyTags(demo.allergy),
    for (final part in demo.tag.split(' · '))
      if (part.isNotEmpty) StudentTag(label: part, tone: _toneOf(part)),
  ];

  /// A peanut allergy travels with its EpiPen, which is why a row can carry
  /// two red tags.
  static List<StudentTag> _allergyTags(String allergy) => switch (allergy) {
    'Peanuts' => const <StudentTag>[
      StudentTag(label: 'Peanut allergy', tone: TagTone.allergy),
      StudentTag(label: 'EpiPen', tone: TagTone.allergy),
    ],
    'Dairy' => const <StudentTag>[
      StudentTag(label: 'Dairy free', tone: TagTone.allergy),
    ],
    'Eggs' => const <StudentTag>[
      StudentTag(label: 'Egg allergy', tone: TagTone.allergy),
    ],
    'Latex' => const <StudentTag>[
      StudentTag(label: 'Latex allergy', tone: TagTone.allergy),
    ],
    _ => const <StudentTag>[],
  };

  static TagTone _toneOf(String label) => switch (label) {
    'Sibling' || 'New' || 'Moving up' || 'Naps' => TagTone.student,
    _ => TagTone.neutral,
  };

  /// Two days off for a half-day student, one for a late pickup, five for
  /// everybody else.
  static List<bool> _weekdaysOf(DemoStudent demo) {
    if (demo.tag.contains('Half day Fri')) {
      return const <bool>[true, true, true, true, false];
    }
    if (demo.tag.contains('Half day')) {
      return const <bool>[true, false, true, false, true];
    }
    return const <bool>[true, true, true, true, true];
  }

  static String _scheduleOf(DemoStudent demo) {
    if (demo.tag.contains('Half day Fri')) {
      return '7:30 – 17:30, Mon to Thu';
    }
    if (demo.tag.contains('Half day')) return '8:30 – 13:00, Mon Wed Fri';
    return '7:30 – 17:30, five days';
  }

  // --- Profile --------------------------------------------------------------

  @override
  Future<StudentProfileRecord> loadProfile(String id) async {
    await Future<void>.delayed(_latency);

    final demo = DemoData.students.firstWhere(
      (s) => s.id == id,
      orElse: () => DemoData.sunflower.first,
    );
    final student = _summary(demo);
    final allergies = demo.allergy == 'None recorded' ? null : demo.allergy;

    return StudentProfileRecord(
      student: student,
      activeSinceLabel: '8 Sep 2025',
      gender: 'Not recorded',
      fullTimeEquivalent: '100%',
      custody: 'Both parents',
      hasStateSubsidy: demo.tag.contains('State subsidy'),
      siblingLabel: _siblingLabel(demo),
      address: '42 Bramble Way, Nashua NH 03060',
      notes: 'Sleeps with the blue rabbit. Collected early on Fridays.',
      health: StudentHealthInfo(
        allergies: allergies == null ? null : '$allergies · severe',
        medications: 'Salbutamol inhaler, as needed',
        dietaryRestrictions: 'No pork',
        canFamilyEdit: true,
      ),
      physician: const StudentPhysicianInfo(
        name: 'Elena Marsh',
        email: 'e.marsh@nashuapaeds.com',
        phone: '(603) 555-0190',
        address: '19 Amherst St, Nashua NH 03064',
        notes: 'Call the practice before 5pm for same-day advice.',
      ),
      exam: const StudentExamInfo(
        dateLabel: '14 Mar 2026',
        isCompleted: true,
        notes: 'Cleared for all activities.',
      ),
      dates: StudentDates(
        enrollmentLabel: '4 Sep 2025',
        schoolStartLabel: '8 Sep 2025',
        classroomStartLabel: '8 Sep 2025',
        upcomingMoveLabel: student.movementLabel,
      ),
      guardians: _guardiansOf(demo),
      pickups: _pickupsOf(demo),
      immunizations: _immunizations,
      attendance: _attendanceMonth,
      documents: _documents,
    );
  }

  /// The demo world's own siblings: two students who share a guardian.
  static String? _siblingLabel(DemoStudent demo) {
    for (final other in DemoData.students) {
      if (other.id != demo.id && other.guardianName == demo.guardianName) {
        return '${other.name} · ${other.classroom}';
      }
    }
    return null;
  }

  static List<StudentPerson> _guardiansOf(DemoStudent demo) {
    final surname = demo.guardianName.split(' ').last;
    return <StudentPerson>[
      StudentPerson(
        id: '${demo.id}-g1',
        name: demo.guardianName,
        initials: _initialsOf(demo.guardianName),
        relation: 'Guardian',
        kind: PersonKind.guardian,
        badge: 'Emergency contact',
        badgeTone: PersonBadgeTone.emergency,
        rows: const <InfoRow>[
          InfoRow(StudentsStrings.fieldPhone, '(603) 555-0128'),
          InfoRow(
            StudentsStrings.fieldEmail,
            'first.last@example.com',
            tone: InfoTone.muted,
          ),
          InfoRow(StudentsStrings.fieldSignInPin, '4417'),
          InfoRow(StudentsStrings.fieldLegalCustody, StudentsStrings.yes),
        ],
      ),
      if (_twoParents.contains(demo.id))
        StudentPerson(
          id: '${demo.id}-g2',
          name: 'Emeka $surname',
          initials: _initialsOf('Emeka $surname'),
          relation: 'Parent',
          kind: PersonKind.guardian,
          rows: const <InfoRow>[
            InfoRow(StudentsStrings.fieldPhone, '(603) 555-0164'),
            InfoRow(
              StudentsStrings.fieldEmail,
              'first.last@example.com',
              tone: InfoTone.muted,
            ),
            InfoRow(StudentsStrings.fieldSignInPin, '8290'),
            InfoRow(StudentsStrings.fieldLegalCustody, StudentsStrings.yes),
          ],
        ),
    ];
  }

  /// Only some students have anyone else on the pickup list, which is what
  /// puts the dashed "Add a pickup person" row on its own for the rest.
  static List<StudentPerson> _pickupsOf(DemoStudent demo) {
    if (!_twoParents.contains(demo.id)) return const <StudentPerson>[];
    final surname = demo.guardianName.split(' ').last;
    return <StudentPerson>[
      StudentPerson(
        id: '${demo.id}-p1',
        name: 'Grace $surname',
        initials: _initialsOf('Grace $surname'),
        relation: 'Grandparent',
        kind: PersonKind.pickup,
        badge: 'Fridays only',
        rows: const <InfoRow>[
          InfoRow(StudentsStrings.fieldPhone, '(603) 555-0177'),
          InfoRow(StudentsStrings.fieldSignInPin, '5521'),
          InfoRow(StudentsStrings.addedBy, 'Marcus Whitfield'),
        ],
      ),
      StudentPerson(
        id: '${demo.id}-p2',
        name: 'Tolu Adebayo',
        initials: 'TA',
        relation: 'Family friend',
        kind: PersonKind.pickup,
        badge: 'Expired',
        badgeTone: PersonBadgeTone.lapsed,
        rows: const <InfoRow>[
          InfoRow(StudentsStrings.allowed, 'One-off, 14 Aug 2026'),
          InfoRow(
            StudentsStrings.fieldSignInPin,
            StudentsStrings.noMovement,
            tone: InfoTone.muted,
          ),
          InfoRow(StudentsStrings.addedBy, 'Marcus Whitfield'),
        ],
      ),
    ];
  }

  static String _initialsOf(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // --- Pickers --------------------------------------------------------------

  @override
  Future<List<String>> classroomNames() async {
    await Future<void>.delayed(_latency);
    return _classroomNames;
  }

  @override
  Future<List<String>> tagNames() async {
    await Future<void>.delayed(_latency);
    return _tagNames;
  }

  @override
  Future<List<GuardianOption>> guardianOptions() async {
    await Future<void>.delayed(_latency);
    return <GuardianOption>[
      for (final name in _guardianNames)
        GuardianOption(
          id: name.toLowerCase().replaceAll(' ', '-'),
          name: name,
          email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
        ),
    ];
  }

  @override
  Future<List<StudentSummary>> siblingsNamed(
    String lastName, {
    String? excludeId,
  }) async {
    await Future<void>.delayed(_latency);
    final surname = lastName.trim().toLowerCase();
    if (surname.isEmpty) return const <StudentSummary>[];
    return <StudentSummary>[
      for (final demo in DemoData.students)
        if (demo.id != excludeId &&
            demo.name.split(' ').last.toLowerCase() == surname)
          _summary(demo),
    ];
  }

  // --- Writes ---------------------------------------------------------------

  @override
  Future<StudentSummary> createStudent(StudentDraft draft) async {
    await Future<void>.delayed(_latency);
    final dob = draft.dateOfBirth ?? DemoData.today;
    return StudentSummary(
      id: draft.fullName.toLowerCase().replaceAll(' ', '-'),
      firstName: draft.firstName,
      lastName: draft.lastName,
      initials: _initialsOf(draft.fullName),
      classroomName: draft.classroomName ?? '',
      status: draft.status,
      dateOfBirth: dob,
      age: StudentsFormats.age(dob, DemoData.today),
      tags: draft.tags,
      hasGuardian: draft.guardianId != null || draft.guardianName.isNotEmpty,
    );
  }

  @override
  Future<StudentSummary> updateStudent({
    required String id,
    required StudentDraft draft,
  }) async {
    await Future<void>.delayed(_latency);
    final dob = draft.dateOfBirth ?? DemoData.today;
    return StudentSummary(
      id: id,
      firstName: draft.firstName,
      lastName: draft.lastName,
      initials: _initialsOf(draft.fullName),
      classroomName: draft.classroomName ?? '',
      status: draft.status,
      dateOfBirth: dob,
      age: StudentsFormats.age(dob, DemoData.today),
      tags: draft.tags,
    );
  }

  @override
  Future<StudentSummary> deactivateStudent(String id) async {
    await Future<void>.delayed(_latency);
    final demo = DemoData.students.firstWhere(
      (s) => s.id == id,
      orElse: () => DemoData.sunflower.first,
    );
    final student = _summary(demo);
    return StudentSummary(
      id: student.id,
      firstName: student.firstName,
      lastName: student.lastName,
      initials: student.initials,
      classroomName: student.classroomName,
      status: StudentStatus.inactive,
      dateOfBirth: student.dateOfBirth,
      age: student.age,
      tags: student.tags,
      guardianNames: student.guardianNames,
    );
  }

  // --- Documents ------------------------------------------------------------

  @override
  Future<List<StudentDocumentItem>> loadDocuments(String id) async {
    await Future<void>.delayed(_latency);
    return _documents;
  }

  @override
  Future<PickedFile?> pickFile({bool fromCamera = false}) async {
    await Future<void>.delayed(_latency);
    return fromCamera
        ? const PickedFile(
            name: 'photo-20-aug.jpg',
            kind: DocumentKind.image,
            sizeKb: 940,
          )
        : const PickedFile(
            name: 'exam-mar-2026.pdf',
            kind: DocumentKind.pdf,
            sizeKb: 1843,
          );
  }

  @override
  Future<StudentDocumentItem> uploadDocument({
    required String studentId,
    required DocumentDraft draft,
    required ValueChanged<double> onProgress,
  }) async {
    final willFail = _uploadCall.isOdd;
    _uploadCall += 1;

    for (var tick = 1; tick <= _uploadTicks; tick++) {
      await Future<void>.delayed(_uploadTick);
      final sent = tick / _uploadTicks;
      // The frame's failed state stops at 62%, which is where a dropped
      // connection lands it.
      if (willFail && sent > .62) {
        throw const _UploadFailed();
      }
      onProgress(sent);
    }

    return StudentDocumentItem(
      id: 'doc-$_uploadCall',
      name: draft.fileName ?? '',
      type: draft.type ?? '',
      kind: draft.kind,
      detail: draft.type ?? '',
      sizeKb: draft.sizeKb,
    );
  }

  // --- The world M05 adds on top of DemoData --------------------------------

  static const List<String> _classroomNames = <String>['Sunflower', 'Bluebell'];

  /// The school's own tag list, already loaded for the filter and the tag
  /// editor, which is why Tags is a searchable dropdown and not four chips.
  static const List<String> _tagNames = <String>[
    'Allergy card',
    'Asthma',
    'Bus',
    'Dairy free',
    'Egg allergy',
    'EpiPen',
    'Half day',
    'Half day Fri',
    'Halal',
    'Inhaler',
    'Late pickup',
    'Latex allergy',
    'Medication',
    'Moving up',
    'Naps',
    'New',
    'No photos',
    'Nut free',
    'Peanut allergy',
    'Second language',
    'Sibling',
    'Speech support',
    'Staff child',
    'State subsidy',
    'Vegetarian',
  ];

  static List<String> get _guardianNames {
    final names = <String>{
      for (final demo in DemoData.students) demo.guardianName,
    }.toList()..sort();
    return names;
  }

  /// Enrolled, not started: 5a's three dashed rows.
  static final List<StudentSummary> _upcoming = <StudentSummary>[
    _upcomingRow('ines', 'Ines', 'Vidal', 'IV', 'Bluebell'),
    _upcomingRow('bo', 'Bo', 'Chen', 'BC', 'Sunflower'),
    _upcomingRow('halima', 'Halima', 'Yusuf', 'HY', 'Bluebell'),
  ];

  static StudentSummary _upcomingRow(
    String id,
    String first,
    String last,
    String initials,
    String classroom,
  ) {
    final dob = DateTime(2025, 2, 14);
    return StudentSummary(
      id: id,
      firstName: first,
      lastName: last,
      initials: initials,
      classroomName: classroom,
      status: StudentStatus.upcoming,
      dateOfBirth: dob,
      age: StudentsFormats.age(dob, DemoData.today),
      scheduleLabel: '9:00 – 16:00, Mon to Thu',
    );
  }

  /// Students with a move booked. The roster row is the one place this date
  /// is shown, which is what the Dates tab's note says.
  static const Map<String, String> _movements = <String, String>{
    'amara': '1 Sep 2026 · to Willow',
    'ada': '12 Jan 2027 · to Sunflower',
    'rumi': '3 Nov 2026 · to Sunflower',
  };

  /// Nobody linked, so the row carries the "No parent" flag and the family
  /// cannot be messaged.
  static const Set<String> _withoutGuardian = <String>{'hazel', 'sena'};

  /// Students whose record carries a second parent and a pickup list.
  static const Set<String> _twoParents = <String>{'amara', 'aria', 'sam'};

  /// Dates of birth, which the demo world holds only as an age string.
  static final Map<String, DateTime> _birthDates = <String, DateTime>{
    'aria': DateTime(2022, 6, 12),
    'theo': DateTime(2021, 12, 30),
    'jonah': DateTime(2022, 9, 4),
    'lila': DateTime(2022, 4, 18),
    'micah': DateTime(2022, 11, 2),
    'nora': DateTime(2022, 7, 21),
    'sam': DateTime(2022, 3, 9),
    'ivy': DateTime(2022, 12, 15),
    'rafael': DateTime(2022, 8, 6),
    'hazel': DateTime(2022, 10, 11),
    'omar': DateTime(2022, 2, 24),
    'poppy': DateTime(2023, 1, 19),
    'elias': DateTime(2022, 5, 27),
    'amara': DateTime(2023, 2, 7),
    'rumi': DateTime(2023, 12, 3),
    'beau': DateTime(2024, 3, 16),
    'ada': DateTime(2023, 8, 22),
    'kofi': DateTime(2023, 9, 28),
    'wren': DateTime(2024, 2, 5),
    'otto': DateTime(2023, 11, 14),
    'maya': DateTime(2024, 4, 8),
    'felix': DateTime(2024, 1, 25),
    'sena': DateTime(2023, 10, 17),
  };

  /// The Immunization tab. The due date, the status and the exemption reason
  /// are already returned by the endpoint the overdue line reads.
  static final List<ImmunizationRecord> _immunizations = <ImmunizationRecord>[
    ImmunizationRecord(
      name: 'DTaP · dose 4',
      detail: StudentsStrings.givenOn('12 Sep 2025'),
      status: ImmunizationStatus.completed,
    ),
    ImmunizationRecord(
      name: 'Polio (IPV)',
      detail: StudentsStrings.givenOn('12 Sep 2025'),
      status: ImmunizationStatus.completed,
    ),
    ImmunizationRecord(
      name: 'Hib',
      detail: StudentsStrings.givenOn('4 Mar 2025'),
      status: ImmunizationStatus.completed,
    ),
    ImmunizationRecord(
      name: 'MMR · dose 2',
      detail: StudentsStrings.dueOn('12 Sep 2026'),
      status: ImmunizationStatus.due,
    ),
    ImmunizationRecord(
      name: 'Varicella',
      detail: StudentsStrings.wasDueOn('1 Jul 2026'),
      status: ImmunizationStatus.overdue,
      dueDateLabel: '1 July',
    ),
    const ImmunizationRecord(
      name: 'Hepatitis B',
      detail: StudentsStrings.exemptionOnFile,
      status: ImmunizationStatus.exempt,
    ),
  ];

  static const AttendanceMonth _attendanceMonth = AttendanceMonth(
    name: 'August',
    daysIn: 13,
    absent: 1,
    hours: 91,
    days: <AttendanceDay>[
      AttendanceDay(
        dateLabel: 'Thu 20 Aug',
        detail: 'In 8:42 · kiosk',
        status: AttendanceStatus.signedIn,
        hoursLabel: StudentsStrings.stillIn,
      ),
      AttendanceDay(
        dateLabel: 'Wed 19 Aug',
        detail: '8:05 – 16:40 · kiosk',
        status: AttendanceStatus.signedOut,
        hoursLabel: '8h 35m',
      ),
      AttendanceDay(
        dateLabel: 'Tue 18 Aug',
        detail: 'Sick, called in at 7:20',
        status: AttendanceStatus.absent,
        hoursLabel: StudentsStrings.noMovement,
      ),
      AttendanceDay(
        dateLabel: 'Mon 17 Aug',
        detail: '8:12 – 17:05 · app',
        status: AttendanceStatus.signedOut,
        hoursLabel: '8h 53m',
      ),
      AttendanceDay(
        dateLabel: 'Fri 15 Aug',
        detail: '8:20 – 16:15 · kiosk',
        status: AttendanceStatus.signedOut,
        hoursLabel: '7h 55m',
      ),
      AttendanceDay(
        dateLabel: 'Thu 14 Aug',
        detail: '8:30 – 16:00 · kiosk',
        status: AttendanceStatus.signedOut,
        hoursLabel: '7h 30m',
      ),
    ],
  );

  static final List<StudentDocumentItem> _documents = <StudentDocumentItem>[
    StudentDocumentItem(
      id: 'doc-enrollment',
      name: 'Enrollment form',
      type: 'Registration Forms',
      kind: DocumentKind.pdf,
      detail: StudentsStrings.documentDetail(
        'Registration Forms',
        '4 Sep 2025',
      ),
      sizeKb: 420,
    ),
    StudentDocumentItem(
      id: 'doc-immunization',
      name: 'Immunization record',
      type: 'Health Forms',
      kind: DocumentKind.pdf,
      detail: StudentsStrings.documentDetail(
        'Health Forms',
        StudentsStrings.expiresOn('12 Sep 2026'),
      ),
      sizeKb: 611,
    ),
    StudentDocumentItem(
      id: 'doc-custody',
      name: 'Custody agreement',
      type: 'Special Program Forms',
      kind: DocumentKind.pdf,
      detail: StudentsStrings.documentDetail(
        'Special Program Forms',
        '4 Sep 2025',
      ),
      sizeKb: 288,
    ),
    StudentDocumentItem(
      id: 'doc-birth',
      name: 'Birth certificate',
      type: 'Birth Certificate',
      kind: DocumentKind.image,
      detail: StudentsStrings.documentDetail('Birth Certificate', '4 Sep 2025'),
      sizeKb: 1204,
    ),
  ];
}

/// What a dropped upload throws. Private: the cubit only needs to know the
/// send did not finish, which is all 5f's failed card says.
class _UploadFailed implements Exception {
  const _UploadFailed();
}
