import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/staff/models/staff_attendance_day.dart';
import 'package:wowcare/redesign/features/staff/models/staff_document.dart';
import 'package:wowcare/redesign/features/staff/models/staff_important_dates.dart';
import 'package:wowcare/redesign/features/staff/models/staff_member.dart';
import 'package:wowcare/redesign/features/staff/models/staff_shift.dart';

/// A street address, as the profile shows it and the edit form writes it.
///
/// Mirrors `StaffProfileAddress`, whose `/api/v1/staff-address` call is
/// separate from the profile's own, which is why it is its own object here.
@immutable
class StaffAddress extends Equatable {
  const StaffAddress({
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
  });

  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;

  bool get isEmpty =>
      street.isEmpty &&
      line2.isEmpty &&
      city.isEmpty &&
      state.isEmpty &&
      zipCode.isEmpty;

  /// "8 Cedar Row, Nashua NH 03063", the way 6c prints it.
  String get formatted {
    final head = <String>[
      if (street.isNotEmpty) street,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
    ].join(', ');
    final tail = <String>[
      if (state.isNotEmpty) state,
      if (zipCode.isNotEmpty) zipCode,
    ].join(' ');
    if (head.isEmpty) return tail;
    return tail.isEmpty ? head : '$head $tail';
  }

  StaffAddress copyWith({
    String? street,
    String? line2,
    String? city,
    String? state,
    String? zipCode,
  }) => StaffAddress(
    street: street ?? this.street,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
  );

  @override
  List<Object?> get props => [street, line2, city, state, zipCode];
}

/// One staff record with everything its five tabs draw (6c).
///
/// Mirrors `StaffProfile` from `lib/domain/features/staff/entities/`, joined
/// with the schedules, the attendance profile, the staff dates and the
/// document list, which is exactly the fan-out `staff_profile_screen.dart`
/// already performs across four calls.
@immutable
class StaffProfile extends Equatable {
  const StaffProfile({
    required this.member,
    this.address = const StaffAddress(),
    this.birthDate,
    this.week = const <StaffShift>[],
    this.contractedMinutes = 0,
    this.days = const <StaffAttendanceDay>[],
    this.summary,
    this.dates = const StaffImportantDates(),
    this.documents = const <StaffDocument>[],
    this.asOf,
  });

  final StaffMember member;
  final StaffAddress address;
  final DateTime? birthDate;

  /// This week, dated, Monday first. The 6c Schedule tab.
  final List<StaffShift> week;

  /// What the contract says the week adds up to, whatever the shifts total.
  final int contractedMinutes;

  final List<StaffAttendanceDay> days;
  final StaffAttendanceSummary? summary;
  final StaffImportantDates dates;
  final List<StaffDocument> documents;

  /// The school's day, as the record was read. Time in this app is
  /// school-timezone based rather than the device's, so an age and an expiry
  /// are measured against this and never against `DateTime.now()`.
  final DateTime? asOf;

  String get id => member.id;
  String get name => member.name;
  String get firstName => member.firstName;

  /// Whole years, for "4 Nov 1991 (34 yrs)".
  int? get age {
    final born = birthDate;
    final today = asOf;
    if (born == null || today == null) return null;
    var years = today.year - born.year;
    final hadBirthday =
        today.month > born.month ||
        (today.month == born.month && today.day >= born.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  /// True when [document] has run out against the school's day.
  bool isExpired(StaffDocument document) =>
      asOf != null && document.isExpired(asOf!);

  /// The first break of the week, which is what the ratio note is about.
  StaffShift? get firstBreak {
    for (final shift in week) {
      if (shift.hasBreak) return shift;
    }
    return null;
  }

  StaffProfile copyWith({
    StaffMember? member,
    StaffAddress? address,
    DateTime? birthDate,
    List<StaffShift>? week,
    List<StaffDocument>? documents,
  }) => StaffProfile(
    member: member ?? this.member,
    address: address ?? this.address,
    birthDate: birthDate ?? this.birthDate,
    week: week ?? this.week,
    contractedMinutes: contractedMinutes,
    days: days,
    summary: summary,
    dates: dates,
    documents: documents ?? this.documents,
    asOf: asOf,
  );

  @override
  List<Object?> get props => [
    member,
    address,
    birthDate,
    week,
    contractedMinutes,
    days,
    summary,
    dates,
    documents,
    asOf,
  ];
}
