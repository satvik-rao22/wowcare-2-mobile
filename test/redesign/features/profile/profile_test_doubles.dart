import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

/// A source the tests drive by hand.
///
/// A fake rather than a mock: a profile load reads the record and the build
/// info in one go, and 13e's toggle is a read followed by a write, so setting
/// the world up says more about the behaviour than stubbing each call.
class FakeProfileSource implements ProfileSource {
  FakeProfileSource({
    ProfileSnapshot? snapshot,
    List<NotificationPreferenceGroup>? preferences,
    this.states = const <String>['New Hampshire', 'Vermont'],
  }) : snapshot = snapshot ?? ProfileSnapshot(record: staffRecord),
       preferences = preferences ?? defaultPreferences;

  ProfileSnapshot snapshot;
  List<NotificationPreferenceGroup> preferences;
  List<String> states;

  /// How long a read takes. Zero unless a test wants to see the state a
  /// screen is in before the answer arrives.
  Duration readDelay = Duration.zero;

  /// Set, every read throws, which is how 13f's failed state is reached.
  bool throwsOnRead = false;

  /// Set, every write throws.
  bool throwsOnWrite = false;

  /// Set, the photo upload stops part way, which is 13a's failed card.
  bool uploadFails = false;

  int fetchCalls = 0;
  ProfileFormData? saved;
  NotificationPreferenceGroup? updated;
  String? removedPhotoFor;
  String? changedFrom;
  String? changedTo;

  // --- Reads ----------------------------------------------------------------

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    fetchCalls += 1;
    if (readDelay > Duration.zero) await Future<void>.delayed(readDelay);
    if (throwsOnRead) throw const ProfileUnavailable();
    return snapshot;
  }

  @override
  Future<List<NotificationPreferenceGroup>> fetchPreferences(
    String userId,
  ) async {
    if (throwsOnRead) throw const ProfileUnavailable();
    return preferences;
  }

  @override
  Future<List<String>> stateNames() async {
    if (throwsOnRead) throw const ProfileUnavailable();
    return states;
  }

  @override
  Future<AppBuildInfo> buildInfo() async =>
      const AppBuildInfo(version: '2.4.1', build: '318');

  // --- Writes ---------------------------------------------------------------

  @override
  Future<ProfileRecord> saveProfile(String userId, ProfileFormData form) async {
    if (throwsOnWrite) throw const ProfileUnavailable();
    saved = form;
    return snapshot.record.copyWith(
      firstName: form.firstName,
      lastName: form.lastName,
      phone: form.phone,
      address: form.toAddress(country: 'United States'),
    );
  }

  @override
  Stream<double> uploadPhoto(String userId) async* {
    yield .5;
    if (uploadFails) throw const ProfileUnavailable();
    yield 1;
  }

  @override
  Future<void> removePhoto(String userId) async {
    if (throwsOnWrite) throw const ProfileUnavailable();
    removedPhotoFor = userId;
  }

  @override
  Future<void> updatePreference(
    String userId,
    NotificationPreferenceGroup group,
  ) async {
    if (throwsOnWrite) throw const ProfileUnavailable();
    updated = group;
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String current,
    required String next,
  }) async {
    if (throwsOnWrite) throw const ProfileUnavailable();
    changedFrom = current;
    changedTo = next;
  }

  // --- The world the tests start from --------------------------------------

  static const ProfileAddress address = ProfileAddress(
    street: '118 Wexford Lane',
    line2: 'Apt 4',
    city: 'Nashua',
    state: 'New Hampshire',
    zipCode: '03063',
    country: 'United States',
  );

  /// Marcus, the Director, as `PreviewProfileSource` has him.
  static const ProfileRecord staffRecord = ProfileRecord(
    id: 'marcus',
    kind: ProfileKind.staff,
    firstName: 'Marcus',
    lastName: 'Whitfield',
    email: 'marcus.whitfield@mapleview.school',
    designation: 'Director',
    schoolName: 'Maple View',
    phone: '(615) 442-9087',
    address: address,
    roleLabels: <String>['Admin', 'Parent'],
    signInPin: '4821',
    hasPhoto: true,
    workSchedule: WorkSchedule(
      shifts: <ScheduleEntry>[
        ScheduleEntry(day: Weekday.monday, start: '7:00 AM', end: '4:00 PM'),
        ScheduleEntry(day: Weekday.tuesday, start: '7:00 AM', end: '4:00 PM'),
      ],
      breaks: <ScheduleEntry>[
        ScheduleEntry(day: Weekday.monday, start: '12:30', end: '1:00 PM'),
      ],
    ),
  );

  /// Ngozi, the Guardian, with the two students she is on the record for.
  static const ProfileRecord guardianRecord = ProfileRecord(
    id: 'ngozi',
    kind: ProfileKind.guardian,
    firstName: 'Ngozi',
    lastName: 'Okafor',
    email: 'ngozi.okafor@example.com',
    designation: 'Guardian',
    schoolName: 'Maple View',
    phone: '(603) 512-7740',
    address: address,
    roleLabels: <String>['Parent'],
    signInPin: '7390',
    hasPhoto: true,
    children: <ProfileChild>[
      ProfileChild(
        id: 'amara',
        name: 'Amara Okafor',
        initials: 'AO',
        classroomName: 'Sunflower',
        attendance: AttendanceStatus.signedIn,
        timeLabel: '8:09 AM',
      ),
      ProfileChild(
        id: 'sam',
        name: 'Sam Okafor',
        initials: 'SO',
        classroomName: 'Sunflower',
        attendance: AttendanceStatus.notMarked,
      ),
    ],
  );

  static const List<NotificationPreferenceGroup> defaultPreferences =
      <NotificationPreferenceGroup>[
        NotificationPreferenceGroup(
          groupCode: 'g1',
          title: 'Attendance',
          description: 'A student is signed in, signed out or marked absent',
          categoryCode: 'STUDENTS',
          categoryName: 'Students',
          displayOrder: 1,
          channels: <String, bool>{
            NotificationChannel.inApp: true,
            NotificationChannel.email: true,
            NotificationChannel.push: true,
          },
        ),
        NotificationPreferenceGroup(
          groupCode: 'g2',
          title: 'Activities and incidents',
          description: 'An activity is recorded, an incident needs approval',
          categoryCode: 'STUDENTS',
          categoryName: 'Students',
          displayOrder: 2,
          channels: <String, bool>{
            NotificationChannel.inApp: true,
            NotificationChannel.push: false,
          },
        ),
        NotificationPreferenceGroup(
          groupCode: 'g5',
          title: 'Shifts and scheduling',
          description: 'Shifts published or edited, a block under ratio',
          categoryCode: 'STAFF',
          categoryName: 'Staff',
          displayOrder: 3,
          channels: <String, bool>{
            NotificationChannel.inApp: true,
            NotificationChannel.email: false,
            NotificationChannel.push: true,
          },
        ),
      ];
}
