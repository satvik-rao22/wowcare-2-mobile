import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/staff/models/staff_role.dart';
import 'package:wowcare/redesign/features/staff/models/staff_shift.dart';
import 'package:wowcare/redesign/features/staff/models/staff_status.dart';

/// One staff member, as the 6a row draws them and as 6c, 6e and 6f head with
/// them.
///
/// Mirrors `StaffMember` from `lib/domain/features/staff/entities/`, plus the
/// two fields the roster row also shows: today's attendance, which the
/// by-staff attendance summary already returns, and today's shift, which
/// comes back on the staff list as `workScheduleByDay` /
/// `breakScheduleByDay`. Nothing here is new API work.
@immutable
class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.designation,
    required this.role,
    required this.status,
    this.primaryClassroom = '',
    this.allowedClassrooms = const <String>[],
    this.phone = '',
    this.email = '',
    this.signInPin = '',
    this.attendance = AttendanceStatus.notMarked,
    this.attendanceTime = '',
    this.todayShift,
    this.jobTags = const <String>[],
    this.since,
  });

  /// The staff code. `dana` here; `STF_*` after Phase 5.
  final String id;
  final String name;
  final String initials;

  /// Lead teacher, Floater, Director. The line under the name.
  final String designation;

  final StaffRole role;
  final StaffStatus status;

  /// Where they are rostered. Blank means no classroom, which a Floater and
  /// a Director both legitimately are.
  final String primaryClassroom;

  /// Every classroom they may cover, primary included.
  final List<String> allowedClassrooms;

  final String phone;
  final String email;

  /// Four digits, read off `GET /api/v1/staff/{code}/sign-in-pin`. Read only:
  /// the module never sets or resets it.
  final String signInPin;

  final AttendanceStatus attendance;

  /// "7:52 AM", "Not Marked", "Marked 6:58 AM": whatever the attendance
  /// summary carries beside the status.
  final String attendanceTime;

  final StaffShift? todayShift;
  final List<String> jobTags;

  /// When this status began: hired on, started on, deactivated on.
  final DateTime? since;

  String get firstName => name.split(' ').first;

  bool get isActive => status == StaffStatus.active;
  bool get isUpcoming => status == StaffStatus.upcoming;
  bool get isInactive => status == StaffStatus.inactive;

  bool get hasClassroom => primaryClassroom.isNotEmpty;

  /// Every classroom this record touches, for the 6b "Allowed in" filter.
  Set<String> get classroomScope => <String>{
    if (hasClassroom) primaryClassroom,
    ...allowedClassrooms,
  };

  /// True when [other] would see this record under the staff read boundary:
  /// a teacher sees the colleagues they share a classroom with (6e).
  bool sharesClassroomWith(String? classroom) =>
      classroom != null && classroomScope.contains(classroom);

  StaffMember copyWith({
    StaffStatus? status,
    String? phone,
    String? email,
    String? name,
    String? primaryClassroom,
    List<String>? allowedClassrooms,
    DateTime? since,
  }) => StaffMember(
    id: id,
    name: name ?? this.name,
    initials: initials,
    designation: designation,
    role: role,
    status: status ?? this.status,
    primaryClassroom: primaryClassroom ?? this.primaryClassroom,
    allowedClassrooms: allowedClassrooms ?? this.allowedClassrooms,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    signInPin: signInPin,
    attendance: attendance,
    attendanceTime: attendanceTime,
    todayShift: todayShift,
    jobTags: jobTags,
    since: since ?? this.since,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    designation,
    role,
    status,
    primaryClassroom,
    allowedClassrooms,
    phone,
    email,
    signInPin,
    attendance,
    attendanceTime,
    todayShift,
    jobTags,
    since,
  ];
}
