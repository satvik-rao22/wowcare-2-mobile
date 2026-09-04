import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

/// A source the tests drive by hand.
///
/// A fake rather than a mock: every M05 cubit reads several of these methods
/// in one load, and stubbing each call would say less about the behaviour
/// than setting the world up and asking what the cubit made of it.
class FakeStudentsSource implements StudentsSource {
  FakeStudentsSource({
    RosterResult? roster,
    StudentProfileRecord? profile,
    this.classrooms = const <String>['Sunflower', 'Bluebell'],
    this.tags = const <String>['Naps', 'Peanut allergy'],
    this.guardians = const <GuardianOption>[],
    this.siblings = const <StudentSummary>[],
    this.documents = const <StudentDocumentItem>[],
    this.picked,
  }) : roster = roster ?? RosterLoaded(defaultSnapshot),
       profile = profile ?? defaultProfile;

  RosterResult roster;
  StudentProfileRecord profile;
  List<String> classrooms;
  List<String> tags;
  List<GuardianOption> guardians;
  List<StudentSummary> siblings;
  List<StudentDocumentItem> documents;
  PickedFile? picked;

  /// Set, every read throws, which is how the failed states are reached.
  bool throwsOnRead = false;

  /// Set, every write throws.
  bool throwsOnWrite = false;

  /// Set, an upload stops part way, which is 5f's failed card.
  bool uploadFails = false;

  int rosterCalls = 0;
  StudentDraft? created;
  StudentDraft? updated;
  String? deactivated;

  // --- Reads ----------------------------------------------------------------

  @override
  Future<RosterResult> loadRoster({
    required Persona persona,
    String? scopeClassroom,
    String query = '',
  }) async {
    rosterCalls += 1;
    if (throwsOnRead) throw const _Failed();
    return roster;
  }

  @override
  Future<StudentProfileRecord> loadProfile(String id) async {
    if (throwsOnRead) throw const _Failed();
    return profile;
  }

  @override
  Future<List<String>> classroomNames() async {
    if (throwsOnRead) throw const _Failed();
    return classrooms;
  }

  @override
  Future<List<String>> tagNames() async {
    if (throwsOnRead) throw const _Failed();
    return tags;
  }

  @override
  Future<List<GuardianOption>> guardianOptions() async {
    if (throwsOnRead) throw const _Failed();
    return guardians;
  }

  @override
  Future<List<StudentSummary>> siblingsNamed(
    String lastName, {
    String? excludeId,
  }) async {
    if (throwsOnRead) throw const _Failed();
    return siblings;
  }

  @override
  Future<List<StudentDocumentItem>> loadDocuments(String id) async {
    if (throwsOnRead) throw const _Failed();
    return documents;
  }

  // --- Writes ---------------------------------------------------------------

  @override
  Future<StudentSummary> createStudent(StudentDraft draft) async {
    if (throwsOnWrite) throw const _Failed();
    created = draft;
    return student(id: 'new', first: draft.firstName, last: draft.lastName);
  }

  @override
  Future<StudentSummary> updateStudent({
    required String id,
    required StudentDraft draft,
  }) async {
    if (throwsOnWrite) throw const _Failed();
    updated = draft;
    return student(id: id, first: draft.firstName, last: draft.lastName);
  }

  @override
  Future<StudentSummary> deactivateStudent(String id) async {
    if (throwsOnWrite) throw const _Failed();
    deactivated = id;
    return student(id: id, status: StudentStatus.inactive);
  }

  @override
  Future<PickedFile?> pickFile({bool fromCamera = false}) async => picked;

  @override
  Future<StudentDocumentItem> uploadDocument({
    required String studentId,
    required DocumentDraft draft,
    required ValueChanged<double> onProgress,
  }) async {
    onProgress(.5);
    if (uploadFails) throw const _Failed();
    onProgress(1);
    return StudentDocumentItem(
      id: 'uploaded',
      name: draft.fileName ?? '',
      type: draft.type ?? '',
      kind: draft.kind,
      detail: draft.type ?? '',
    );
  }

  // --- The world the tests start from --------------------------------------

  static final DateTime today = DateTime(2026, 8, 20);

  static StudentSummary student({
    String id = 'aria',
    String first = 'Aria',
    String last = 'Rowan',
    String classroom = 'Sunflower',
    StudentStatus status = StudentStatus.active,
    AttendanceStatus attendance = AttendanceStatus.signedIn,
    List<StudentTag> tags = const <StudentTag>[],
    bool hasGuardian = true,
    List<String> guardianNames = const <String>['Nadia Rowan'],
  }) => StudentSummary(
    id: id,
    firstName: first,
    lastName: last,
    initials: '${first[0]}${last[0]}',
    classroomName: classroom,
    status: status,
    dateOfBirth: DateTime(2022, 6, 12),
    age: '4 yrs 2 mo',
    attendance: attendance,
    attendanceTimeLabel: '8:12',
    tags: tags,
    scheduleLabel: '7:30 – 17:30, five days',
    hasGuardian: hasGuardian,
    guardianNames: guardianNames,
  );

  static final RosterSnapshot defaultSnapshot = RosterSnapshot(
    students: <StudentSummary>[
      student(),
      student(
        id: 'theo',
        first: 'Theo',
        last: 'Nkemelu',
        attendance: AttendanceStatus.notMarked,
        guardianNames: const <String>['Chidi Nkemelu'],
      ),
      student(
        id: 'rumi',
        first: 'Rumi',
        last: 'Tanaka',
        classroom: 'Bluebell',
        tags: const <StudentTag>[
          StudentTag(label: 'Naps', tone: TagTone.student),
        ],
        guardianNames: const <String>['Kenji Tanaka'],
      ),
    ],
    upcoming: <StudentSummary>[
      student(
        id: 'bo',
        first: 'Bo',
        last: 'Chen',
        status: StudentStatus.upcoming,
        attendance: AttendanceStatus.notMarked,
      ),
    ],
    classroomNames: const <String>['Sunflower', 'Bluebell'],
    tagNames: const <String>['Naps', 'Peanut allergy'],
    guardianNames: const <String>['Nadia Rowan', 'Kenji Tanaka'],
  );

  static final StudentProfileRecord defaultProfile = StudentProfileRecord(
    student: student(),
    activeSinceLabel: '8 Sep 2025',
    gender: 'Not recorded',
    fullTimeEquivalent: '100%',
    custody: 'Both parents',
    address: '42 Bramble Way, Nashua NH 03060',
    notes: 'Sleeps with the blue rabbit.',
    health: const StudentHealthInfo(
      allergies: 'Peanut · severe',
      medications: 'Salbutamol inhaler, as needed',
      canFamilyEdit: true,
    ),
    dates: const StudentDates(
      enrollmentLabel: '4 Sep 2025',
      schoolStartLabel: '8 Sep 2025',
    ),
    guardians: const <StudentPerson>[
      StudentPerson(
        id: 'g1',
        name: 'Nadia Rowan',
        initials: 'NR',
        relation: 'Guardian',
        kind: PersonKind.guardian,
        badge: 'Emergency contact',
        badgeTone: PersonBadgeTone.emergency,
        rows: <InfoRow>[InfoRow('Phone', '(603) 555-0128')],
      ),
    ],
    immunizations: const <ImmunizationRecord>[
      ImmunizationRecord(
        name: 'Varicella',
        detail: 'Was due 1 Jul 2026',
        status: ImmunizationStatus.overdue,
        dueDateLabel: '1 July',
      ),
    ],
    attendance: const AttendanceMonth(
      name: 'August',
      daysIn: 13,
      absent: 1,
      hours: 91,
      days: <AttendanceDay>[
        AttendanceDay(
          dateLabel: 'Thu 20 Aug',
          detail: 'In 8:42 · kiosk',
          status: AttendanceStatus.signedIn,
          hoursLabel: 'still in',
        ),
      ],
    ),
    documents: const <StudentDocumentItem>[
      StudentDocumentItem(
        id: 'doc-enrollment',
        name: 'Enrollment form',
        type: 'Registration Forms',
        kind: DocumentKind.pdf,
        detail: 'Registration Forms · 4 Sep 2025',
      ),
    ],
  );
}

class _Failed implements Exception {
  const _Failed();
}
