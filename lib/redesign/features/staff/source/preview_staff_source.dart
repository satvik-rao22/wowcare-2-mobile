import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';

/// M06's fixtures: Maple View's team on the design's own day.
///
/// Every staff member is one of `DemoData.staffMembers`, which already carries the
/// name, the initials, the designation, the scope, the Sign-In PIN and
/// today's attendance. What the 6a rows and the 6c tabs also draw, namely the
/// phone, the email, the allowed classrooms, the shift, the job tags and the
/// dates, is added here from the frames' own `_script.js` staff array, so
/// the module reads as the same school as the rest of the app.
///
/// One staff member is added beyond `DemoData`: Lena Fontaine, upcoming, which is
/// what the 6a "Starting soon" tile and the dashed upcoming row need and what
/// the roster otherwise has nobody to show.
class PreviewStaffSource implements StaffSource {
  const PreviewStaffSource();

  static const Duration _latency = Duration(milliseconds: 420);
  static const Duration _writeLatency = Duration(milliseconds: 340);

  /// The design's day, so a fixture never drifts with the wall clock.
  static DateTime get today => DemoData.today;

  static const String _emailDomain = 'mapleview.school';

  // --- What the frames add on top of DemoData --------------------------------

  static const Map<String, _Detail> _details = <String, _Detail>{
    'marcus': _Detail(
      role: StaffRole.admin,
      phone: '(603) 555-0101',
      since: '2019-08-12',
      start: 450,
      end: 1050,
      breakStart: 780,
      breakEnd: 810,
      jobTags: <String>['Safeguarding lead'],
    ),
    'dana': _Detail(
      phone: '(603) 555-0113',
      classroom: 'Sunflower',
      allowed: <String>['Sunflower', 'Bluebell'],
      since: '2024-01-12',
      start: 450,
      end: 990,
      breakStart: 720,
      breakEnd: 750,
      jobTags: <String>['First aid', 'EYFS'],
    ),
    'priya': _Detail(
      phone: '(603) 555-0121',
      classroom: 'Bluebell',
      allowed: <String>['Bluebell', 'Sunflower'],
      since: '2023-03-06',
      start: 510,
      end: 1020,
      breakStart: 750,
      breakEnd: 780,
      jobTags: <String>['First aid', 'EYFS'],
    ),
    'ruth': _Detail(
      phone: '(603) 555-0128',
      classroom: 'Acorn',
      allowed: <String>['Acorn'],
      since: '2022-09-05',
      start: 480,
      end: 990,
      breakStart: 720,
      breakEnd: 750,
      jobTags: <String>['First aid'],
    ),
    'hugo': _Detail(
      phone: '(603) 555-0139',
      classroom: 'Acorn',
      allowed: <String>['Acorn'],
      since: '2025-02-03',
      start: 780,
      end: 1080,
      jobTags: <String>['First aid'],
    ),
    'grace': _Detail(
      phone: '(603) 555-0147',
      since: '2021-06-14',
      start: 390,
      end: 870,
      breakStart: 660,
      breakEnd: 690,
      jobTags: <String>['Food hygiene'],
    ),
    'noor': _Detail(
      phone: '(603) 555-0152',
      since: '2023-11-20',
      start: 480,
      end: 960,
      breakStart: 750,
      breakEnd: 780,
    ),
    'jamal': _Detail(
      phone: '(603) 555-0163',
      classroom: 'Sunflower',
      allowed: <String>['Sunflower', 'Bluebell'],
      since: '2024-08-19',
      start: 480,
      end: 960,
      breakStart: 750,
      breakEnd: 780,
      jobTags: <String>['First aid'],
    ),
    'tomas': _Detail(
      phone: '(603) 555-0171',
      classroom: 'Bluebell',
      allowed: <String>['Bluebell'],
      since: '2025-02-03',
      start: 780,
      end: 1080,
      jobTags: <String>['First aid'],
    ),
    'aisha': _Detail(
      phone: '(603) 555-0186',
      classroom: 'Sunflower',
      allowed: <String>['Sunflower'],
      since: '2022-04-11',
      start: 450,
      end: 990,
      breakStart: 720,
      breakEnd: 750,
      jobTags: <String>['First aid', 'EYFS'],
    ),
  };

  /// The one hire the design needs who is not in the demo world yet: the
  /// hire whose start date has not arrived.
  static final StaffMember _upcoming = StaffMember(
    id: 'lena',
    name: 'Lena Fontaine',
    initials: 'LF',
    designation: 'Floater',
    role: StaffRole.staff,
    status: StaffStatus.upcoming,
    primaryClassroom: 'Bluebell',
    allowedClassrooms: const <String>['Sunflower', 'Bluebell', 'Willow'],
    phone: '(603) 555-0156',
    email: 'lena.fontaine@$_emailDomain',
    signInPin: '6614',
    todayShift: const StaffShift(
      weekday: DateTime.thursday,
      startMinutes: 480,
      endMinutes: 960,
      breakStartMinutes: 750,
      breakEndMinutes: 780,
    ),
    jobTags: const <String>['First aid', 'Food hygiene'],
    since: DateTime(2026, 9, 7),
  );

  // --- The roster ------------------------------------------------------------

  static List<StaffMember> get members => <StaffMember>[
    for (final person in DemoData.staffMembers) _memberOf(person),
    _upcoming,
  ];

  static StaffMember _memberOf(DemoStaff person) {
    final detail = _details[person.id] ?? const _Detail();
    return StaffMember(
      id: person.id,
      name: person.name,
      initials: person.initials,
      designation: person.designation,
      role: detail.role,
      status: StaffStatus.active,
      primaryClassroom: detail.classroom,
      allowedClassrooms: detail.allowed,
      phone: detail.phone,
      email: _emailOf(person.name),
      signInPin: person.signInPin,
      attendance: _attendanceOf(person.attendance),
      attendanceTime: person.timeLabel,
      todayShift: detail.shiftOn(today.weekday),
      jobTags: detail.jobTags,
      since: detail.sinceDate,
    );
  }

  static String _emailOf(String name) =>
      '${name.toLowerCase().replaceAll(' ', '.')}@$_emailDomain';

  static AttendanceStatus _attendanceOf(DemoAttendance attendance) =>
      switch (attendance) {
        DemoAttendance.signedIn => AttendanceStatus.signedIn,
        DemoAttendance.signedOut => AttendanceStatus.signedOut,
        DemoAttendance.absent => AttendanceStatus.absent,
        DemoAttendance.notMarked => AttendanceStatus.notMarked,
      };

  static StaffRoster get _roster {
    final people = members;
    final designations = <String>{
      for (final member in people) member.designation,
    }.toList()..sort();

    return StaffRoster(
      members: people,
      activeCount: people.where((member) => member.isActive).length,
      upcomingCount: people.where((member) => member.isUpcoming).length,
      designations: designations,
      classrooms: DemoData.classroomNames,
      asOf: today,
    );
  }

  @override
  Future<StaffRoster> loadRoster() async {
    await Future<void>.delayed(_latency);
    return _roster;
  }

  // --- One record ------------------------------------------------------------

  @override
  Future<StaffProfile> loadProfile(String id) async {
    await Future<void>.delayed(_latency);
    return profileOf(id);
  }

  /// The 6c record for [id]. Public so a test can build the same fixture the
  /// screen is given without going through the latency.
  static StaffProfile profileOf(String id) {
    final member = members.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => members.first,
    );
    final detail = _details[member.id] ?? const _Detail();
    final week = _weekFor(detail);

    return StaffProfile(
      member: member,
      address: _addressOf(member),
      birthDate: _birthDateOf(member),
      week: week,
      contractedMinutes: week.fold(
        0,
        (total, shift) => total + shift.workedMinutes,
      ),
      days: _daysFor(member, detail),
      summary: StaffAttendanceSummary(
        month: DateTime(today.year, today.month),
        daysAttended: 14,
        daysAbsent: member.attendance == AttendanceStatus.absent ? 2 : 1,
        workedMinutes: 6740,
      ),
      dates: StaffImportantDates(
        hireDate: member.since,
        cdaExamDate: DateTime(2025, 11, 4),
        backgroundCheckDate: member.since?.add(const Duration(days: 6)),
        firstAidExpiry: DateTime(2027, 3, 2),
        physicalCheckupDate: DateTime(2026, 6, 9),
      ),
      documents: _documentsFor(member),
      asOf: today,
    );
  }

  static StaffAddress _addressOf(StaffMember member) => StaffAddress(
    street: '${8 + member.id.length} Cedar Row',
    city: 'Nashua',
    state: 'NH',
    zipCode: '03063',
  );

  static DateTime _birthDateOf(StaffMember member) =>
      DateTime(1991 - member.id.length, 11, 4);

  /// Today and the four working days after it, which is the week 6c draws.
  static List<StaffShift> _weekFor(_Detail detail) {
    final days = <StaffShift>[];
    var day = DateTime(today.year, today.month, today.day);
    while (days.length < 5) {
      if (day.weekday <= DateTime.friday) {
        days.add(detail.shiftOn(day.weekday, date: day) ?? _dayOff(day));
      }
      day = day.add(const Duration(days: 1));
    }
    // Wednesday is the day off the frame draws, so the card has one of each.
    return <StaffShift>[
      for (final shift in days)
        shift.weekday == DateTime.wednesday ? _dayOff(shift.date!) : shift,
    ];
  }

  static StaffShift _dayOff(DateTime date) =>
      StaffShift(weekday: date.weekday, date: date);

  /// The last six working days, ending today.
  static List<StaffAttendanceDay> _daysFor(StaffMember member, _Detail detail) {
    final days = <StaffAttendanceDay>[];
    var day = DateTime(today.year, today.month, today.day);
    while (days.length < 6) {
      if (day.weekday <= DateTime.friday) {
        final isToday = days.isEmpty;
        final isAbsent = days.length == 2;
        days.add(
          StaffAttendanceDay(
            date: day,
            status: isAbsent
                ? AttendanceStatus.absent
                : isToday
                ? member.attendance
                : AttendanceStatus.signedOut,
            startMinutes: isAbsent ? null : detail.start,
            endMinutes: isAbsent || isToday ? null : detail.end,
            note: isAbsent ? 'Called in 6:40' : '',
          ),
        );
      }
      day = day.subtract(const Duration(days: 1));
    }
    return days;
  }

  static List<StaffDocument> _documentsFor(StaffMember member) {
    final hired = member.since ?? today;
    return <StaffDocument>[
      StaffDocument(
        id: '${member.id}-contract',
        name: 'Signed contract',
        type: 'Contract',
        kind: StaffDocumentKind.pdf,
        addedOn: hired,
      ),
      StaffDocument(
        id: '${member.id}-first-aid',
        name: 'First aid certificate',
        type: 'Certificate',
        kind: StaffDocumentKind.pdf,
        addedOn: hired,
        expiresOn: DateTime(2027, 3, 2),
      ),
      StaffDocument(
        id: '${member.id}-background',
        name: 'Background check',
        type: 'Certificate',
        kind: StaffDocumentKind.pdf,
        addedOn: hired.add(const Duration(days: 6)),
      ),
      StaffDocument(
        id: '${member.id}-photo-id',
        name: 'Photo ID',
        type: 'Identification',
        kind: StaffDocumentKind.image,
        addedOn: hired.subtract(const Duration(days: 2)),
      ),
    ];
  }

  // --- What a form may pick from ---------------------------------------------

  @override
  Future<StaffOptions> loadOptions() async {
    await Future<void>.delayed(_latency);
    return options;
  }

  /// The two designation lists are `add_staff_screen.dart`'s own, verbatim.
  static const StaffOptions options = StaffOptions(
    adminDesignations: <String>[
      'Director',
      'Admin',
      'Assistant Director',
      'Owner',
    ],
    staffDesignations: <String>[
      'Lead teacher',
      'Associate Teacher',
      'Assistant teacher',
      'Floater',
    ],
    classrooms: DemoData.classroomNames,
    jobTags: <String>['First aid', 'EYFS', 'Food hygiene', 'Safeguarding lead'],
  );

  // --- Writes ----------------------------------------------------------------

  @override
  Future<StaffMember> createStaff(StaffDraft draft) async {
    await Future<void>.delayed(_writeLatency);
    return StaffMember(
      id: draft.fullName.toLowerCase().replaceAll(' ', '-'),
      name: draft.fullName,
      initials: _initialsOf(draft.fullName),
      designation: draft.designation ?? '',
      role: draft.role,
      status: draft.status,
      primaryClassroom: draft.primaryClassroom ?? '',
      allowedClassrooms: draft.effectiveAllowed.toList(),
      phone: draft.phone,
      email: draft.email,
      signInPin: '8140',
      todayShift: draft.week.isEmpty ? null : draft.week.first,
      jobTags: draft.jobTags.toList(),
      since: today,
    );
  }

  static String _initialsOf(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Future<StaffProfile> updateDetails({
    required String id,
    required StaffDetailsDraft draft,
  }) async {
    await Future<void>.delayed(_writeLatency);
    final profile = profileOf(id);
    return profile.copyWith(
      member: profile.member.copyWith(
        name: draft.fullName,
        phone: draft.phone,
        email: draft.email,
      ),
      address: StaffAddress(
        street: draft.street,
        line2: draft.line2,
        city: draft.city,
        state: draft.state,
        zipCode: draft.zipCode,
      ),
    );
  }

  @override
  Future<StaffProfile> updateSchedule({
    required String id,
    required List<StaffShift> week,
  }) async {
    await Future<void>.delayed(_writeLatency);
    return profileOf(id).copyWith(week: week);
  }

  @override
  Future<StaffMember> setActive({
    required String id,
    required bool isActive,
  }) async {
    await Future<void>.delayed(_writeLatency);
    final member = profileOf(id).member;
    return member.copyWith(
      status: isActive ? StaffStatus.active : StaffStatus.inactive,
      since: today,
    );
  }

  @override
  Future<StaffDocument> addDocument({
    required String staffId,
    required String name,
    required String type,
    DateTime? expiresOn,
  }) async {
    await Future<void>.delayed(_writeLatency);
    return StaffDocument(
      id: '$staffId-${name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      type: type,
      kind: StaffDocumentKind.pdf,
      addedOn: today,
      expiresOn: expiresOn,
    );
  }
}

/// The frame detail that `DemoData` does not carry, per staff member. Times are
/// minutes after midnight.
class _Detail {
  const _Detail({
    this.role = StaffRole.staff,
    this.phone = '',
    this.classroom = '',
    this.allowed = const <String>[],
    this.since = '',
    this.start,
    this.end,
    this.breakStart,
    this.breakEnd,
    this.jobTags = const <String>[],
  });

  final StaffRole role;
  final String phone;
  final String classroom;
  final List<String> allowed;
  final String since;
  final int? start;
  final int? end;
  final int? breakStart;
  final int? breakEnd;
  final List<String> jobTags;

  DateTime? get sinceDate => since.isEmpty ? null : DateTime.parse(since);

  StaffShift? shiftOn(int weekday, {DateTime? date}) => start == null
      ? null
      : StaffShift(
          weekday: weekday,
          date: date,
          startMinutes: start,
          endMinutes: end,
          breakStartMinutes: breakStart,
          breakEndMinutes: breakEnd,
          classroom: classroom,
        );
}
