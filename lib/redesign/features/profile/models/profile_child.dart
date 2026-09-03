import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// One of a guardian's students, as the "Your children" card lists them
/// (13c). Mirrors what `ParentChildCubit` holds per child: the record, its
/// classroom and today's attendance.
@immutable
class ProfileChild extends Equatable {
  const ProfileChild({
    required this.id,
    required this.name,
    required this.initials,
    required this.classroomName,
    required this.attendance,
    this.timeLabel = '',
  });

  final String id;
  final String name;
  final String initials;
  final String classroomName;
  final AttendanceStatus attendance;

  /// "8:09 AM" beside a Signed In status; empty when there is no time.
  final String timeLabel;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    initials,
    classroomName,
    attendance,
    timeLabel,
  ];
}
