import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// Who a Sign-In PIN belongs to. Mirrors `KioskPersona` without the `kiosk`
/// and `unknown` cases: a PIN the fixture does not know is simply invalid.
enum KioskPersona { staff, guardian }

/// One of a guardian's students, as the PIN verification returns them.
/// Mirrors `KioskStudent`: a code, a name, a classroom and today's status.
@immutable
class KioskStudent extends Equatable {
  const KioskStudent({
    required this.id,
    required this.name,
    required this.initials,
    required this.classroomName,
    required this.attendance,
    required this.timeLabel,
  });

  final String id;
  final String name;
  final String initials;
  final String classroomName;
  final AttendanceStatus attendance;

  /// "8:09 AM", "expected today", "Marked 7:55 AM".
  final String timeLabel;

  bool get isSignedIn => attendance == AttendanceStatus.signedIn;

  String get firstName => name.split(' ').first;

  KioskStudent copyWith({AttendanceStatus? attendance, String? timeLabel}) =>
      KioskStudent(
        id: id,
        name: name,
        initials: initials,
        classroomName: classroomName,
        attendance: attendance ?? this.attendance,
        timeLabel: timeLabel ?? this.timeLabel,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    classroomName,
    attendance,
    timeLabel,
  ];
}

/// What verifying a PIN returns. Mirrors `KioskPinResultEntity`: a persona,
/// then either the staff member and their status, or the guardian and their
/// students.
@immutable
class KioskPinResult extends Equatable {
  const KioskPinResult({
    required this.persona,
    required this.personId,
    required this.personName,
    required this.acceptedAtLabel,
    this.staffAttendance,
    this.students = const <KioskStudent>[],
  });

  final KioskPersona persona;

  /// The staff code or guardian code.
  final String personId;
  final String personName;

  /// When the PIN was accepted, as the family screen shows it ("8:04 AM").
  final String acceptedAtLabel;

  /// Today's status for a staff member. Null for a guardian.
  final AttendanceStatus? staffAttendance;

  /// A guardian's students. Empty for a staff member.
  final List<KioskStudent> students;

  bool get isStaff => persona == KioskPersona.staff;
  bool get isGuardian => persona == KioskPersona.guardian;

  List<KioskStudent> get signedInStudents =>
      students.where((s) => s.isSignedIn).toList();

  List<KioskStudent> get notSignedInStudents =>
      students.where((s) => !s.isSignedIn).toList();

  /// Some students are in and some are not, so the kiosk has to ask which
  /// way this visit goes (2d).
  bool get isMixed =>
      signedInStudents.isNotEmpty && notSignedInStudents.isNotEmpty;

  @override
  List<Object?> get props => [
    persona,
    personId,
    personName,
    acceptedAtLabel,
    staffAttendance,
    students,
  ];
}
