import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/clock_time.dart';

/// 4c's cover card: a classroom that runs short later today.
///
/// The forecast behind it is Scheduling's, read here as the one sentence the
/// staff list can act on.
@immutable
class StaffGap extends Equatable {
  const StaffGap({
    required this.classroomName,
    required this.at,
    required this.body,
  });

  final String classroomName;
  final ClockTime at;

  /// Why, in the school's own words.
  final String body;

  @override
  List<Object?> get props => <Object?>[classroomName, at, body];
}
