import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/profile/models/profile_address.dart';
import 'package:wowcare/redesign/features/profile/models/profile_child.dart';
import 'package:wowcare/redesign/features/profile/models/work_schedule.dart';

/// Which record the signed-in person is: a staff member (from
/// `GET /api/v1/staff/my-profile/{staffCode}`) or a guardian (from
/// `GET /api/v1/guardian/profile`).
enum ProfileKind { staff, guardian }

/// The signed-in person's own record, as My Profile shows it.
///
/// Mirrors `StaffProfile` for the school side (name, email, phone, address,
/// designation, clock PIN, work and break schedules) and the guardian profile
/// map for parents (name, email, phone, address, children). [roleLabels] is
/// `UserProfileState.distinctRolesForCurrentSchool`.
@immutable
class ProfileRecord extends Equatable {
  const ProfileRecord({
    required this.id,
    required this.kind,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.designation,
    required this.schoolName,
    this.phone = '',
    this.address = const ProfileAddress(),
    this.roleLabels = const <String>[],
    this.classroomName,
    this.signInPin = '',
    this.hasPhoto = false,
    this.workSchedule,
    this.children = const <ProfileChild>[],
  });

  final String id;
  final ProfileKind kind;
  final String firstName;
  final String lastName;
  final String email;

  /// Director, Lead Teacher, Guardian.
  final String designation;
  final String schoolName;
  final String phone;
  final ProfileAddress address;

  /// Admin, Staff, Parent: every role this account holds at this school.
  final List<String> roleLabels;
  final String? classroomName;

  /// The kiosk clock PIN. Empty when none is set.
  final String signInPin;
  final bool hasPhoto;

  /// Staff only. Null for a guardian.
  final WorkSchedule? workSchedule;

  /// Guardian only. Empty for staff.
  final List<ProfileChild> children;

  bool get isGuardian => kind == ProfileKind.guardian;
  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${_initial(firstName)}${_initial(lastName)}'.toUpperCase();

  static String _initial(String s) => s.isEmpty ? '' : s[0];

  ProfileRecord copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    ProfileAddress? address,
    bool? hasPhoto,
    WorkSchedule? workSchedule,
  }) => ProfileRecord(
    id: id,
    kind: kind,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email,
    designation: designation,
    schoolName: schoolName,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    roleLabels: roleLabels,
    classroomName: classroomName,
    signInPin: signInPin,
    hasPhoto: hasPhoto ?? this.hasPhoto,
    workSchedule: workSchedule ?? this.workSchedule,
    children: children,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    firstName,
    lastName,
    email,
    designation,
    schoolName,
    phone,
    address,
    roleLabels,
    classroomName,
    signInPin,
    hasPhoto,
    workSchedule,
    children,
  ];
}

/// What a profile fetch returns: the record, and whether it came off the
/// device cache because the network was unreachable (13f offline over cache).
@immutable
class ProfileSnapshot extends Equatable {
  const ProfileSnapshot({
    required this.record,
    this.isFromCache = false,
    this.cachedAtLabel,
  });

  final ProfileRecord record;
  final bool isFromCache;

  /// "9:02 AM": when the cached copy was saved. Only set with [isFromCache].
  final String? cachedAtLabel;

  @override
  List<Object?> get props => <Object?>[record, isFromCache, cachedAtLabel];
}

/// The build the app reports in the profile footer.
@immutable
class AppBuildInfo extends Equatable {
  const AppBuildInfo({required this.version, required this.build});

  final String version;
  final String build;

  @override
  List<Object?> get props => <Object?>[version, build];
}
