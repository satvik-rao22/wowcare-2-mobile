import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';

/// The one demo world every module's fixtures draw from, lifted from the
/// design frames so the app reads as one school rather than sixteen.
///
/// Maple View is the school, Whitlow Early Years its organization. Marcus
/// Whitfield directs it (Admin), Dana Whitfield leads Sunflower (Staff), and
/// Ngozi Okafor is Amara's guardian (Guardian). The rosters are the design's
/// own `SUN` / `BLU` / `STAFF` arrays.
///
/// Fixture-only. Nothing here survives Phase 5.
abstract final class DemoData {
  static const String schoolName = 'Maple View';
  static const String organizationName = 'Whitlow Early Years';

  /// The design draws every frame on this day.
  static final DateTime today = DateTime(2026, 8, 20, 9, 41);

  static const List<String> classroomNames = <String>[
    'Sunflower',
    'Bluebell',
    'Acorn',
    'Willow',
    'Maple',
  ];

  // --- The three personas. One account holds all three so Switch Profile ---
  // --- is exercised; sign-in picks whichever the reviewer asks for. --------

  static const SessionUser admin = SessionUser(
    id: 'marcus',
    fullName: 'Marcus Whitfield',
    firstName: 'Marcus',
    initials: 'MW',
    designation: 'Director',
    organizationName: organizationName,
    schoolName: schoolName,
    email: 'marcus.whitfield@mapleview.school',
    personas: <Persona>[Persona.admin, Persona.staff, Persona.guardian],
  );

  static const SessionUser staff = SessionUser(
    id: 'dana',
    fullName: 'Dana Whitfield',
    firstName: 'Dana',
    initials: 'DW',
    designation: 'Lead Teacher',
    organizationName: organizationName,
    schoolName: schoolName,
    classroomName: 'Sunflower',
    email: 'dana.whitfield@mapleview.school',
    personas: <Persona>[Persona.staff, Persona.admin, Persona.guardian],
  );

  static const SessionUser guardian = SessionUser(
    id: 'ngozi',
    fullName: 'Ngozi Okafor',
    firstName: 'Ngozi',
    initials: 'NO',
    designation: 'Guardian',
    organizationName: organizationName,
    schoolName: schoolName,
    email: 'ngozi.okafor@example.com',
    personas: <Persona>[Persona.guardian, Persona.admin, Persona.staff],
  );

  /// The organizations the account can open, 1b.
  static const List<DemoOrganization> organizations = <DemoOrganization>[
    DemoOrganization(
      id: 'whitlow',
      name: organizationName,
      roleLabel: 'Admin',
      schools: <DemoSchool>[
        DemoSchool(id: 'mapleview', name: schoolName),
        DemoSchool(id: 'riverside', name: 'Riverside Campus'),
        DemoSchool(id: 'hillcrest', name: 'Hillcrest Annex', isLocked: true),
      ],
    ),
    DemoOrganization(
      id: 'meadow',
      name: 'Meadow Lane Nursery',
      roleLabel: 'Lead Teacher',
      schools: <DemoSchool>[DemoSchool(id: 'meadow', name: 'Meadow Lane')],
    ),
    DemoOrganization(
      id: 'harbour',
      name: 'Harbour Kids Co-op',
      roleLabel: 'Relief staff',
      schools: <DemoSchool>[DemoSchool(id: 'harbour', name: 'Harbour Kids')],
    ),
  ];

  // --- Students: [id, name, initials, attendance, time, guardian, age,
  // --- tag, allergy], classroom by list. Attendance: in / out / nm / ab. ----

  static const List<DemoStudent> sunflower = <DemoStudent>[
    DemoStudent(
      'aria',
      'Aria Rowan',
      'AR',
      'in',
      '8:12 AM',
      'Nadia Rowan',
      '4y 2m',
      'Sibling · Half day Fri',
      'Peanuts',
      'Sunflower',
    ),
    DemoStudent(
      'theo',
      'Theo Nkemelu',
      'TN',
      'in',
      '8:04 AM',
      'Chidi Nkemelu',
      '4y 7m',
      'Bus',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'jonah',
      'Jonah Park',
      'JP',
      'nm',
      'expected today',
      'Grace Park',
      '3y 11m',
      'Late pickup',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'lila',
      'Lila Suarez',
      'LS',
      'ab',
      'Marked 7:55 AM',
      'Elena Suarez',
      '4y 4m',
      '',
      'Dairy',
      'Sunflower',
    ),
    DemoStudent(
      'micah',
      'Micah Bell',
      'MB',
      'in',
      '8:20 AM',
      'Rhea Bell',
      '3y 9m',
      '',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'nora',
      'Nora Adeyemi',
      'NA',
      'in',
      '7:58 AM',
      'Tolu Adeyemi',
      '4y 1m',
      'Sibling',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'sam',
      'Sam Okafor',
      'SO',
      'out',
      '9:20 AM',
      'Ngozi Okafor',
      '4y 5m',
      'Half day',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'ivy',
      'Ivy Chen',
      'IC',
      'in',
      '8:35 AM',
      'Wei Chen',
      '3y 8m',
      '',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'rafael',
      'Rafael Duarte',
      'RD',
      'in',
      '8:41 AM',
      'Sofia Duarte',
      '4y 0m',
      'Sibling',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'hazel',
      'Hazel Byrne',
      'HB',
      'nm',
      'expected today',
      'Maeve Byrne',
      '3y 10m',
      '',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'omar',
      'Omar Haddad',
      'OH',
      'in',
      '8:15 AM',
      'Noor Haddad',
      '4y 6m',
      'Staff child',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'poppy',
      'Poppy Lund',
      'PL',
      'in',
      '8:27 AM',
      'Ingrid Lund',
      '3y 7m',
      '',
      'Eggs',
      'Sunflower',
    ),
    DemoStudent(
      'elias',
      'Elias Moreau',
      'EM',
      'nm',
      'expected today',
      'Camille Moreau',
      '4y 3m',
      '',
      'None recorded',
      'Sunflower',
    ),
    DemoStudent(
      'amara',
      'Amara Okafor',
      'AO',
      'in',
      '8:09 AM',
      'Ngozi Okafor',
      '3y 6m',
      'Sibling',
      'None recorded',
      'Sunflower',
    ),
  ];

  static const List<DemoStudent> bluebell = <DemoStudent>[
    DemoStudent(
      'rumi',
      'Rumi Tanaka',
      'RT',
      'in',
      '8:02 AM',
      'Kenji Tanaka',
      '2y 8m',
      '',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'beau',
      'Beau Ellis',
      'BE',
      'in',
      '8:19 AM',
      'Harper Ellis',
      '2y 5m',
      'Bus',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'ada',
      'Ada Kowalski',
      'AK',
      'in',
      '8:30 AM',
      'Piotr Kowalski',
      '3y 0m',
      'Moving up',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'kofi',
      'Kofi Mensah',
      'KM',
      'in',
      '8:11 AM',
      'Abena Mensah',
      '2y 11m',
      '',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'wren',
      'Wren Halloran',
      'WH',
      'in',
      '8:44 AM',
      'Saoirse Halloran',
      '2y 6m',
      '',
      'Latex',
      'Bluebell',
    ),
    DemoStudent(
      'otto',
      'Otto Lindqvist',
      'OL',
      'in',
      '8:07 AM',
      'Elsa Lindqvist',
      '2y 9m',
      '',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'maya',
      'Maya Ibrahim',
      'MI',
      'nm',
      'expected today',
      'Layla Ibrahim',
      '2y 4m',
      '',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'felix',
      'Felix Duarte',
      'FD',
      'ab',
      'Marked 8:02 AM',
      'Sofia Duarte',
      '2y 7m',
      'Sibling',
      'None recorded',
      'Bluebell',
    ),
    DemoStudent(
      'sena',
      'Sena Adjei',
      'SA',
      'nm',
      'expected today',
      'Kwame Adjei',
      '2y 10m',
      'New',
      'None recorded',
      'Bluebell',
    ),
  ];

  static List<DemoStudent> get students => <DemoStudent>[
    ...sunflower,
    ...bluebell,
  ];

  /// Ngozi's children, for the guardian persona.
  static List<DemoStudent> get guardianChildren =>
      students.where((s) => s.guardianName == guardian.fullName).toList();

  // --- Staff: [id, name, initials, attendance, time, designation, scope, PIN]

  static const List<DemoStaff> staffMembers = <DemoStaff>[
    DemoStaff(
      'marcus',
      'Marcus Whitfield',
      'MW',
      'in',
      '7:34 AM',
      'Director',
      'All classrooms',
      '4821',
    ),
    DemoStaff(
      'dana',
      'Dana Whitfield',
      'DW',
      'in',
      '7:48 AM',
      'Lead Teacher',
      'Sunflower',
      '5106',
    ),
    DemoStaff(
      'priya',
      'Priya Raman',
      'PR',
      'in',
      '7:52 AM',
      'Teacher',
      'Bluebell',
      '2277',
    ),
    DemoStaff(
      'ruth',
      'Ruth Adeyinka',
      'RA',
      'in',
      '7:41 AM',
      'Teacher',
      'Acorn',
      '3390',
    ),
    DemoStaff(
      'hugo',
      'Hugo Marsh',
      'HM',
      'in',
      '7:55 AM',
      'Assistant Teacher',
      'Acorn',
      '7715',
    ),
    DemoStaff(
      'grace',
      'Grace Lindley',
      'GL',
      'in',
      '6:40 AM',
      'Cook',
      'Kitchen',
      '8802',
    ),
    DemoStaff(
      'noor',
      'Noor Haddad',
      'NH',
      'in',
      '8:05 AM',
      'Admin Assistant',
      'Office',
      '4408',
    ),
    DemoStaff(
      'jamal',
      'Jamal Ortiz',
      'JO',
      'nm',
      'Not Marked',
      'Assistant Teacher',
      'Sunflower · Bluebell',
      '6631',
    ),
    DemoStaff(
      'tomas',
      'Tomas Berg',
      'TB',
      'out',
      '9:12 AM',
      'Assistant Teacher',
      'Bluebell',
      '9024',
    ),
    DemoStaff(
      'aisha',
      'Aisha Bello',
      'AB',
      'ab',
      'Marked 6:58 AM',
      'Teacher',
      'Sunflower',
      '1187',
    ),
  ];
}

/// Today's attendance, as the design encodes it.
enum DemoAttendance {
  signedIn,
  signedOut,
  notMarked,
  absent;

  static DemoAttendance parse(String code) => switch (code) {
    'in' => DemoAttendance.signedIn,
    'out' => DemoAttendance.signedOut,
    'ab' => DemoAttendance.absent,
    _ => DemoAttendance.notMarked,
  };
}

class DemoStudent {
  const DemoStudent(
    this.id,
    this.name,
    this.initials,
    this._attendance,
    this.timeLabel,
    this.guardianName,
    this.age,
    this.tag,
    this.allergy,
    this.classroom,
  );

  final String id;
  final String name;
  final String initials;
  final String _attendance;

  /// "8:12 AM", "expected today", "Marked 7:55 AM".
  final String timeLabel;
  final String guardianName;
  final String age;
  final String tag;
  final String allergy;
  final String classroom;

  DemoAttendance get attendance => DemoAttendance.parse(_attendance);
  String get firstName => name.split(' ').first;
}

class DemoStaff {
  const DemoStaff(
    this.id,
    this.name,
    this.initials,
    this._attendance,
    this.timeLabel,
    this.designation,
    this.scope,
    this.signInPin,
  );

  final String id;
  final String name;
  final String initials;
  final String _attendance;
  final String timeLabel;
  final String designation;

  /// The classroom(s), or Kitchen / Office / All classrooms.
  final String scope;
  final String signInPin;

  DemoAttendance get attendance => DemoAttendance.parse(_attendance);
  String get firstName => name.split(' ').first;
}

class DemoOrganization {
  const DemoOrganization({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.schools,
  });

  final String id;
  final String name;

  /// "Your role here: Admin".
  final String roleLabel;
  final List<DemoSchool> schools;
}

class DemoSchool {
  const DemoSchool({
    required this.id,
    required this.name,
    this.isLocked = false,
  });

  final String id;
  final String name;

  /// 1c's locked row: a school the account cannot open.
  final bool isLocked;
}
