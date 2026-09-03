import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// What a guardian's student did today, as far as the app already knows
/// (3P1's activity strip).
@immutable
class ActivityTally extends Equatable {
  const ActivityTally({
    this.napStartedLabel,
    this.meals = 0,
    this.photos = 0,
    this.bathroom = 0,
  });

  /// "12:20". Null when no nap is logged.
  final String? napStartedLabel;
  final int meals;
  final int photos;
  final int bathroom;

  bool get isEmpty =>
      napStartedLabel == null && meals == 0 && photos == 0 && bathroom == 0;

  @override
  List<Object?> get props => [napStartedLabel, meals, photos, bathroom];
}

/// One of a guardian's students, and their day (3P1).
@immutable
class ChildDay extends Equatable {
  const ChildDay({
    required this.id,
    required this.name,
    required this.initials,
    required this.classroomName,
    required this.age,
    required this.attendance,
    required this.dayEndsLabel,
    required this.activities,
    this.inTimeLabel,
    this.isReminderOn = false,
  });

  final String id;
  final String name;
  final String initials;
  final String classroomName;
  final String age;

  final AttendanceStatus attendance;

  /// "8:04 AM". Null until the student is Signed In.
  final String? inTimeLabel;

  /// "4:30 PM".
  final String dayEndsLabel;

  final ActivityTally activities;

  /// Tell me before the school day ends.
  final bool isReminderOn;

  String get firstName => name.split(' ').first;
  bool get isSignedIn => attendance == AttendanceStatus.signedIn;

  ChildDay copyWith({
    AttendanceStatus? attendance,
    String? inTimeLabel,
    bool? isReminderOn,
  }) => ChildDay(
    id: id,
    name: name,
    initials: initials,
    classroomName: classroomName,
    age: age,
    attendance: attendance ?? this.attendance,
    inTimeLabel: inTimeLabel ?? this.inTimeLabel,
    dayEndsLabel: dayEndsLabel,
    activities: activities,
    isReminderOn: isReminderOn ?? this.isReminderOn,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    classroomName,
    age,
    attendance,
    inTimeLabel,
    dayEndsLabel,
    activities,
    isReminderOn,
  ];
}
