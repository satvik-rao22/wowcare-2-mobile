import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/models/student_status.dart';
import 'package:wowcare/redesign/features/students/models/student_tag.dart';

/// One student, as the roster knows them (5a).
///
/// Mirrors `lib/domain/features/student/entities/student.dart` field for
/// field: `code` is [id], `firstName` / `lastName`, `status`, `classroom`,
/// `hasGuardian`, `dob`, `movementDate`, `tags`, `schedule` (the abbreviated
/// weekdays) and `scheduleByDay`. [attendance] and [attendanceTimeLabel] come
/// from the today sign-in status map the list already loads, which is why the
/// dot on the avatar and the count on a classroom header cost nothing new.
@immutable
class StudentSummary extends Equatable {
  const StudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.initials,
    required this.classroomName,
    required this.status,
    required this.dateOfBirth,
    required this.age,
    this.attendance = AttendanceStatus.notMarked,
    this.attendanceTimeLabel,
    this.tags = const <StudentTag>[],
    this.weekdays = const <bool>[true, true, true, true, true],
    this.scheduleLabel = '',
    this.movementLabel,
    this.hasGuardian = true,
    this.guardianNames = const <String>[],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String initials;
  final String classroomName;
  final StudentStatus status;

  final DateTime dateOfBirth;

  /// "3 yrs 1 mo", written once by the source rather than at every call site.
  final String age;

  final AttendanceStatus attendance;

  /// "8:42". Null when nothing was recorded today.
  final String? attendanceTimeLabel;

  final List<StudentTag> tags;

  /// Monday to Friday, one flag each: the regular schedule's days.
  final List<bool> weekdays;

  /// "7:30 – 17:30, five days".
  final String scheduleLabel;

  /// "1 Sep 2026 · to Willow". Null when no move is booked.
  final String? movementLabel;

  /// A student with nobody linked cannot be messaged, and the row flags it.
  final bool hasGuardian;

  /// Who is on the record. The roster filters by parent or guardian.
  final List<String> guardianNames;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    initials,
    classroomName,
    status,
    dateOfBirth,
    age,
    attendance,
    attendanceTimeLabel,
    tags,
    weekdays,
    scheduleLabel,
    movementLabel,
    hasGuardian,
    guardianNames,
  ];
}
