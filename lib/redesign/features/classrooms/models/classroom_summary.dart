import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// What a classroom's ratio is saying right now. Two live states only — In
/// Ratio, or short by a count — plus the two quiet states a classroom with
/// nobody in it is allowed to be.
enum ClassroomRatioState {
  /// Enough staff for the students who are in.
  inRatio,

  /// Short. [ClassroomSummary.staffNeeded] says by how many.
  short,

  /// Students on the roll, nobody on the clock.
  noStaff,

  /// Nobody enrolled at all.
  empty,
}

/// One classroom, as the 7a card draws it and as 7c, 7e and 7f head with it.
///
/// Mirrors `Classroom` + `ClassroomDetails` + `RatioMonitoringClassroom` from
/// `lib/domain/features/classroom/entities/`, so linking is a source swap.
///
/// **The ratio is arithmetic here, not a figure from the server.**
/// `staffNeeded = ceil(studentsPresent / allowedRatio) - staffPresent`, which
/// is what `RatioMonitoringClassroom.isRatioGood` decides with on the
/// dashboard. It is never rendered as `9:1`: the card shows counts and a
/// two-state pill.
@immutable
class ClassroomSummary extends Equatable {
  const ClassroomSummary({
    required this.id,
    required this.name,
    required this.ageBand,
    required this.enrolled,
    required this.capacity,
    required this.studentsPresent,
    required this.staffPresent,
    required this.allowedRatio,
    this.minAgeMonths = 0,
    this.maxAgeMonths = 0,
    this.leadName,
    this.leadInitials,
    this.startingSoon = 0,
  });

  /// The classroom code. `sunflower` here; `CLS_*` after Phase 5.
  final String id;
  final String name;

  /// "2 to 3 yrs", built from the entity's min and max age in months.
  final String ageBand;

  final int enrolled;
  final int capacity;

  /// How many of this classroom's students are signed in right now.
  final int studentsPresent;

  /// How many staff are on the clock in it, counting anyone on a break.
  final int staffPresent;

  /// The most students one staff member may supervise here
  /// (`studentsTeacherRatio` on the classroom record). Zero means unset, which
  /// the app treats as no restriction, exactly as the dashboard does.
  final int allowedRatio;

  /// Inclusive age bounds in whole months, as `Classroom.minAgeMonths` and
  /// `maxAgeMonths` carry them. Zero means that side is not enforced.
  final int minAgeMonths;
  final int maxAgeMonths;

  final String? leadName;
  final String? leadInitials;

  /// Students enrolled here whose start date has not arrived (7f).
  final int startingSoon;

  /// The letter in the round tile.
  String get initial => name.isEmpty ? '' : name.substring(0, 1).toUpperCase();

  bool get isEmpty => enrolled == 0;
  bool get hasStaff => staffPresent > 0;
  bool get isFull => capacity > 0 && enrolled >= capacity;
  int get placesLeft => math.max(0, capacity - enrolled);

  /// How many more staff the ratio wants. Zero means In Ratio.
  int get staffNeeded {
    if (studentsPresent == 0 || allowedRatio <= 0) return 0;
    final wanted = (studentsPresent / allowedRatio).ceil();
    return math.max(0, wanted - staffPresent);
  }

  bool get isInRatio => staffNeeded == 0;

  ClassroomRatioState get ratioState {
    if (isEmpty) return ClassroomRatioState.empty;
    if (!hasStaff) return ClassroomRatioState.noStaff;
    return isInRatio ? ClassroomRatioState.inRatio : ClassroomRatioState.short;
  }

  /// How full the roll is, as a whole percent of [capacity].
  int get percentFull =>
      capacity == 0 ? 0 : ((enrolled / capacity) * 100).round();

  /// The trough's fill, clamped so an over-subscribed classroom does not
  /// overrun its own bar.
  double get fillFraction =>
      capacity == 0 ? 0 : (enrolled / capacity).clamp(0, 1).toDouble();

  /// How many students this many staff could hold, for 7h's review step.
  int holdsWithStaff(int staff) =>
      allowedRatio <= 0 ? capacity : staff * allowedRatio;

  /// True when [ageMonths] falls outside an enforced bound. Bounds are
  /// inclusive and a zero bound is unset, matching `Classroom` exactly. It is
  /// a warning, never a block: the web client still assigns.
  bool isAgeOutsideRange(int ageMonths) {
    if (minAgeMonths > 0 && ageMonths < minAgeMonths) return true;
    if (maxAgeMonths > 0 && ageMonths > maxAgeMonths) return true;
    return false;
  }

  ClassroomSummary copyWith({
    int? enrolled,
    int? studentsPresent,
    int? staffPresent,
  }) => ClassroomSummary(
    id: id,
    name: name,
    ageBand: ageBand,
    enrolled: enrolled ?? this.enrolled,
    capacity: capacity,
    studentsPresent: studentsPresent ?? this.studentsPresent,
    staffPresent: staffPresent ?? this.staffPresent,
    allowedRatio: allowedRatio,
    minAgeMonths: minAgeMonths,
    maxAgeMonths: maxAgeMonths,
    leadName: leadName,
    leadInitials: leadInitials,
    startingSoon: startingSoon,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    ageBand,
    enrolled,
    capacity,
    studentsPresent,
    staffPresent,
    allowedRatio,
    minAgeMonths,
    maxAgeMonths,
    leadName,
    leadInitials,
    startingSoon,
  ];
}
