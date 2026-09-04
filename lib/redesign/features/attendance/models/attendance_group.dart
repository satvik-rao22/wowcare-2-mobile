import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_record.dart';

/// One section of the list: a classroom for students, the shift for staff.
///
/// [rows] is what the filter left standing; the counts beside the title are
/// the whole classroom, so narrowing the list to the two absentees does not
/// rewrite the header into a lie.
///
/// The verdict is the classrooms module's own arithmetic written out as
/// counts. Never a ratio figure.
@immutable
class AttendanceGroup extends Equatable {
  const AttendanceGroup({
    required this.title,
    required this.rows,
    required this.presentCount,
    required this.enrolled,
    this.staffPresent = 0,
    this.staffNeeded = 0,
    this.isStaffGroup = false,
  });

  final String title;
  final List<AttendanceRecord> rows;

  /// Signed in across the whole classroom, whatever the filter shows.
  final int presentCount;

  /// How many are on this classroom's roll.
  final int enrolled;

  final int staffPresent;

  /// `max(0, ceil(presentCount / allowedRatio) - staffPresent)`.
  final int staffNeeded;

  final bool isStaffGroup;

  /// Nobody on the clock in a classroom with students in it is its own
  /// sentence, and a louder one than being short-staffed.
  bool get hasNoStaff => !isStaffGroup && staffPresent == 0 && presentCount > 0;

  bool get isShort => hasNoStaff || staffNeeded > 0;

  @override
  List<Object?> get props => <Object?>[
    title,
    rows,
    presentCount,
    enrolled,
    staffPresent,
    staffNeeded,
    isStaffGroup,
  ];
}
