import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/staff/models/staff_role.dart';
import 'package:wowcare/redesign/features/staff/models/staff_shift.dart';
import 'package:wowcare/redesign/features/staff/models/staff_status.dart';

/// Which field an error belongs under, across the three steps of 6d and the
/// edit form.
enum StaffField {
  firstName,
  lastName,
  email,
  phone,
  designation,
  primaryClassroom,
  allowedClassrooms,
  shifts,
}

/// The record 6d is building.
///
/// Mirrors what `CreateSchoolUserUseCase` takes: the name, the contact, the
/// role, the designation, the status and the two classroom fields. There is
/// no PIN here on purpose. The PIN endpoint is read only, so the Sign-In PIN
/// is issued with the record and only ever shown back.
@immutable
class StaffDraft extends Equatable {
  const StaffDraft({
    this.status = StaffStatus.active,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.role = StaffRole.staff,
    this.designation,
    this.primaryClassroom,
    this.allowedClassrooms = const <String>{},
    this.jobTags = const <String>{},
    this.sameShiftEveryDay = true,
    this.week = const <StaffShift>[],
  });

  final StaffStatus status;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final StaffRole role;
  final String? designation;

  /// Where they are rostered. An Admin covers every classroom, so the field
  /// is theirs to leave empty.
  final String? primaryClassroom;

  final Set<String> allowedClassrooms;
  final Set<String> jobTags;

  /// Step three's "Same shift every day". When it is on, the editor writes
  /// Monday's times across the week.
  final bool sameShiftEveryDay;

  final List<StaffShift> week;

  String get fullName => '$firstName $lastName'.trim();

  /// The primary classroom belongs in Allowed too, which is what the existing
  /// screen sends: a staff member may always cover where they are rostered.
  Set<String> get effectiveAllowed => <String>{
    if (primaryClassroom != null && primaryClassroom!.isNotEmpty)
      primaryClassroom!,
    ...allowedClassrooms,
  };

  StaffDraft copyWith({
    StaffStatus? status,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    StaffRole? role,
    String? designation,
    String? primaryClassroom,
    Set<String>? allowedClassrooms,
    Set<String>? jobTags,
    bool? sameShiftEveryDay,
    List<StaffShift>? week,
    bool clearDesignation = false,
    bool clearPrimaryClassroom = false,
  }) => StaffDraft(
    status: status ?? this.status,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    designation: clearDesignation ? null : designation ?? this.designation,
    primaryClassroom: clearPrimaryClassroom
        ? null
        : primaryClassroom ?? this.primaryClassroom,
    allowedClassrooms: allowedClassrooms ?? this.allowedClassrooms,
    jobTags: jobTags ?? this.jobTags,
    sameShiftEveryDay: sameShiftEveryDay ?? this.sameShiftEveryDay,
    week: week ?? this.week,
  );

  @override
  List<Object?> get props => [
    status,
    firstName,
    lastName,
    email,
    phone,
    role,
    designation,
    primaryClassroom,
    allowedClassrooms,
    jobTags,
    sameShiftEveryDay,
    week,
  ];
}

/// What the edit form may change on an existing record.
///
/// Deliberately narrower than [StaffDraft]: designation, role, classrooms and
/// status are set elsewhere, because they decide what a person can do.
@immutable
class StaffDetailsDraft extends Equatable {
  const StaffDetailsDraft({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;

  String get fullName => '$firstName $lastName'.trim();

  StaffDetailsDraft copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? street,
    String? line2,
    String? city,
    String? state,
    String? zipCode,
  }) => StaffDetailsDraft(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    street: street ?? this.street,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
  );

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    phone,
    street,
    line2,
    city,
    state,
    zipCode,
  ];
}
