import 'dart:async';

import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

/// M13's fixtures, lifted from the frames' `_script.js` and keyed by the
/// demo world's `SessionUser.id`: `marcus` (Director), `dana` (Lead Teacher),
/// `ngozi` (Guardian). Writes are remembered for the life of the instance so
/// a save shows up on the way back.
class PreviewProfileSource implements ProfileSource {
  PreviewProfileSource({this.latency = const Duration(milliseconds: 450)});

  /// How long each call pretends the network takes.
  final Duration latency;

  final Map<String, ProfileRecord> _records = <String, ProfileRecord>{
    for (final r in <ProfileRecord>[_marcus, _dana, _ngozi]) r.id: r,
  };

  List<NotificationPreferenceGroup> _preferences = _defaultPreferences();

  static const String _country = 'United States';
  static const AppBuildInfo _build = AppBuildInfo(
    version: '2.4.1',
    build: '318',
  );

  Future<void> _wait() => Future<void>.delayed(latency);

  ProfileRecord _record(String userId) {
    final record = _records[userId];
    if (record == null) {
      throw StateError('No preview profile for "$userId"');
    }
    return record;
  }

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    await _wait();
    return ProfileSnapshot(record: _record(userId));
  }

  @override
  Future<ProfileRecord> saveProfile(String userId, ProfileFormData form) async {
    await _wait();
    final saved = _record(userId).copyWith(
      firstName: form.firstName.trim(),
      lastName: form.lastName.trim(),
      phone: form.phone.trim(),
      address: form.toAddress(country: _country),
    );
    _records[userId] = saved;
    return saved;
  }

  @override
  Stream<double> uploadPhoto(String userId) async* {
    // The real upload is three calls: open a session, stream the bytes,
    // finalize. These are the percentages the old cubit reports at each step.
    for (final step in const <double>[.15, .25, .46, .84, .9, 1]) {
      await Future<void>.delayed(latency ~/ 2);
      yield step;
    }
    _records[userId] = _record(userId).copyWith(hasPhoto: true);
  }

  @override
  Future<void> removePhoto(String userId) async {
    await _wait();
    _records[userId] = _record(userId).copyWith(hasPhoto: false);
  }

  @override
  Future<List<NotificationPreferenceGroup>> fetchPreferences(
    String userId,
  ) async {
    await _wait();
    return List<NotificationPreferenceGroup>.unmodifiable(_preferences);
  }

  @override
  Future<void> updatePreference(
    String userId,
    NotificationPreferenceGroup group,
  ) async {
    await _wait();
    _preferences = <NotificationPreferenceGroup>[
      for (final g in _preferences) g.groupCode == group.groupCode ? group : g,
    ];
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String current,
    required String next,
  }) => _wait();

  @override
  Future<AppBuildInfo> buildInfo() async => _build;

  // --- The three people, from 13a / 13c and DemoData -----------------------

  static final ProfileRecord _marcus = ProfileRecord(
    id: DemoData.admin.id,
    kind: ProfileKind.staff,
    firstName: DemoData.admin.firstName,
    lastName: _lastName(DemoData.admin.fullName),
    email: DemoData.admin.email,
    designation: DemoData.admin.designation,
    schoolName: DemoData.schoolName,
    phone: '(615) 442-9087',
    address: const ProfileAddress(
      street: '118 Wexford Lane',
      line2: 'Apt 4',
      city: 'Nashua',
      state: 'New Hampshire',
      zipCode: '03063',
      country: _country,
    ),
    roleLabels: const <String>['Admin', 'Parent'],
    signInPin: _pinOf(DemoData.admin.id),
    hasPhoto: true,
    workSchedule: const WorkSchedule(
      shifts: <ScheduleEntry>[
        ScheduleEntry(day: Weekday.monday, start: '7:00 AM', end: '4:00 PM'),
        ScheduleEntry(day: Weekday.tuesday, start: '7:00 AM', end: '4:00 PM'),
        ScheduleEntry(
          day: Weekday.wednesday,
          start: '7:00 AM',
          end: '4:00 PM',
        ),
        ScheduleEntry(day: Weekday.thursday, start: '7:00 AM', end: '4:00 PM'),
      ],
      breaks: <ScheduleEntry>[
        ScheduleEntry(day: Weekday.monday, start: '12:30', end: '1:00 PM'),
      ],
    ),
  );

  static final ProfileRecord _dana = ProfileRecord(
    id: DemoData.staff.id,
    kind: ProfileKind.staff,
    firstName: DemoData.staff.firstName,
    lastName: _lastName(DemoData.staff.fullName),
    email: DemoData.staff.email,
    designation: DemoData.staff.designation,
    schoolName: DemoData.schoolName,
    phone: '(615) 208-4471',
    address: const ProfileAddress(
      street: '27 Larkspur Road',
      city: 'Nashua',
      state: 'New Hampshire',
      zipCode: '03063',
      country: _country,
    ),
    roleLabels: const <String>['Staff'],
    classroomName: DemoData.staff.classroomName,
    signInPin: _pinOf(DemoData.staff.id),
    hasPhoto: true,
    workSchedule: const WorkSchedule(
      shifts: <ScheduleEntry>[
        ScheduleEntry(day: Weekday.monday, start: '7:30 AM', end: '4:00 PM'),
        ScheduleEntry(day: Weekday.tuesday, start: '7:30 AM', end: '4:00 PM'),
        ScheduleEntry(
          day: Weekday.wednesday,
          start: '7:30 AM',
          end: '4:00 PM',
        ),
        ScheduleEntry(day: Weekday.thursday, start: '7:30 AM', end: '4:00 PM'),
      ],
      breaks: <ScheduleEntry>[
        ScheduleEntry(day: Weekday.monday, start: '11:30', end: '12:00 PM'),
      ],
    ),
  );

  static final ProfileRecord _ngozi = ProfileRecord(
    id: DemoData.guardian.id,
    kind: ProfileKind.guardian,
    firstName: DemoData.guardian.firstName,
    lastName: _lastName(DemoData.guardian.fullName),
    email: DemoData.guardian.email,
    designation: DemoData.guardian.designation,
    schoolName: DemoData.schoolName,
    phone: '(603) 512-7740',
    address: const ProfileAddress(
      street: '44 Kinsley Street',
      city: 'Nashua',
      state: 'New Hampshire',
      zipCode: '03060',
      country: _country,
    ),
    roleLabels: const <String>['Parent'],
    signInPin: '7390',
    hasPhoto: true,
    children: <ProfileChild>[
      for (final s in DemoData.guardianChildren)
        ProfileChild(
          id: s.id,
          name: s.name,
          initials: s.initials,
          classroomName: s.classroom,
          attendance: _attendance(s.attendance),
          timeLabel: s.attendance == DemoAttendance.signedIn ? s.timeLabel : '',
        ),
    ],
  );

  static String _lastName(String fullName) =>
      fullName.split(' ').skip(1).join(' ');

  static String _pinOf(String staffId) =>
      DemoData.staffMembers.firstWhere((s) => s.id == staffId).signInPin;

  static AttendanceStatus _attendance(DemoAttendance a) => switch (a) {
    DemoAttendance.signedIn => AttendanceStatus.signedIn,
    DemoAttendance.signedOut => AttendanceStatus.signedOut,
    DemoAttendance.absent => AttendanceStatus.absent,
    DemoAttendance.notMarked => AttendanceStatus.notMarked,
  };

  // --- The ten preference groups, from 13e's `n12PrefDefs` -----------------

  static List<NotificationPreferenceGroup> _defaultPreferences() {
    const inApp = NotificationChannel.inApp;
    const email = NotificationChannel.email;
    const push = NotificationChannel.push;

    NotificationPreferenceGroup g(
      int order,
      String code,
      String category,
      String title,
      String description,
      Map<String, bool> channels,
    ) => NotificationPreferenceGroup(
      groupCode: code,
      title: title,
      description: description,
      categoryCode: category.toUpperCase(),
      categoryName: category,
      displayOrder: order,
      channels: channels,
    );

    return <NotificationPreferenceGroup>[
      g(1, 'g1', 'Students', 'Attendance',
          'A student is signed in, signed out or marked absent', const {
        inApp: true,
        email: true,
        push: true,
      }),
      g(2, 'g2', 'Students', 'Activities and incidents',
          'An activity is recorded, an incident needs approval', const {
        inApp: true,
        push: true,
      }),
      g(3, 'g3', 'Students', 'Health and documents',
          'Immunization and physical dates, document expiry', const {
        inApp: true,
        email: true,
        push: false,
      }),
      g(4, 'g4', 'Students', 'Classroom movements',
          'Upcoming, overdue, confirmed and rejected moves', const {
        inApp: true,
        push: true,
      }),
      g(5, 'g5', 'Staff', 'Shifts and scheduling',
          'Shifts published or edited, a block under ratio', const {
        inApp: true,
        email: false,
        push: true,
      }),
      g(6, 'g6', 'Staff', 'Staff attendance',
          'Clock in, clock out, marked absent', const {
        inApp: true,
        push: false,
      }),
      g(7, 'g7', 'Center', 'Billing',
          'Invoice generated or due, payment received', const {
        inApp: true,
        email: true,
        push: true,
      }),
      g(8, 'g8', 'Center', 'Messages',
          'A new message in a conversation you are in', const {
        inApp: true,
        push: true,
      }),
      g(9, 'g9', 'Center', 'Newsletter',
          'A newsletter is sent to your classroom', const {
        inApp: true,
        email: false,
      }),
      g(10, 'g10', 'Center', 'Classrooms and settings',
          'A classroom is added or edited, school settings change', const {
        inApp: true,
      }),
    ];
  }
}
