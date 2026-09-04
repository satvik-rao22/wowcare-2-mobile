import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/models/student_status.dart';

/// What the roster is filtered down to (5b).
///
/// Mirrors the arguments `getStudentPage` already takes: `status`,
/// `classroomCodes`, `tagCodes`, `guardianCodes` and `attendanceStatuses`.
/// Status is pick-one because the endpoint takes one; everything else is a
/// set, which is why Tags is a multi-select dropdown and not four chips.
@immutable
class StudentFilter extends Equatable {
  const StudentFilter({
    this.status = StudentStatus.active,
    this.classrooms = const <String>{},
    this.tags = const <String>{},
    this.guardians = const <String>{},
    this.attendance = const <AttendanceStatus>{},
  });

  final StudentStatus status;
  final Set<String> classrooms;
  final Set<String> tags;
  final Set<String> guardians;
  final Set<AttendanceStatus> attendance;

  /// Active with nothing narrowed: the roster as it opens.
  bool get isDefault =>
      status == StudentStatus.active &&
      classrooms.isEmpty &&
      tags.isEmpty &&
      guardians.isEmpty &&
      attendance.isEmpty;

  /// How many of the five sections are narrowing the list.
  int get narrowedSections =>
      (classrooms.isEmpty ? 0 : 1) +
      (tags.isEmpty ? 0 : 1) +
      (guardians.isEmpty ? 0 : 1) +
      (attendance.isEmpty ? 0 : 1);

  StudentFilter copyWith({
    StudentStatus? status,
    Set<String>? classrooms,
    Set<String>? tags,
    Set<String>? guardians,
    Set<AttendanceStatus>? attendance,
  }) => StudentFilter(
    status: status ?? this.status,
    classrooms: classrooms ?? this.classrooms,
    tags: tags ?? this.tags,
    guardians: guardians ?? this.guardians,
    attendance: attendance ?? this.attendance,
  );

  @override
  List<Object?> get props => [status, classrooms, tags, guardians, attendance];
}
