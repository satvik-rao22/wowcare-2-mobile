import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/clock_time.dart';

/// A staff member's own day, which is the first thing 4d shows them.
///
/// Until [isSignedIn] the classroom below is locked: they can read it and
/// they cannot sign anyone in or out, which is
/// `AttendancePermissionService.hasPermissionToManageStudentAttendance`
/// written as state rather than as a call from a widget.
@immutable
class SelfShift extends Equatable {
  const SelfShift({
    required this.initials,
    required this.classroomName,
    required this.shiftStart,
    this.signedInAt,
    this.signedOutAt,
    this.isInsideGeofence = true,
    this.isCheckingLocation = false,
    this.coverName,
    this.coverArrives,
  });

  final String initials;
  final String classroomName;

  /// When their shift starts, from the roster.
  final ClockTime shiftStart;

  /// When they signed themselves in. Null until they do.
  final ClockTime? signedInAt;

  /// When their day ended. Null until it does.
  final ClockTime? signedOutAt;

  /// Their own sign-in is geofenced. A student sign-in is not.
  final bool isInsideGeofence;
  final bool isCheckingLocation;

  /// Who is due to join them, for the ratio line on the navy card.
  final String? coverName;
  final ClockTime? coverArrives;

  bool get isSignedIn => signedInAt != null && signedOutAt == null;
  bool get isSignedOut => signedOutAt != null;

  /// Only their own sign-in is gated on location.
  bool get canSignSelfIn => isInsideGeofence && !isCheckingLocation;

  bool get hasCover => coverName != null && coverArrives != null;

  SelfShift copyWith({
    ClockTime? signedInAt,
    ClockTime? signedOutAt,
    bool? isInsideGeofence,
    bool? isCheckingLocation,
  }) => SelfShift(
    initials: initials,
    classroomName: classroomName,
    shiftStart: shiftStart,
    signedInAt: signedInAt ?? this.signedInAt,
    signedOutAt: signedOutAt ?? this.signedOutAt,
    isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
    isCheckingLocation: isCheckingLocation ?? this.isCheckingLocation,
    coverName: coverName,
    coverArrives: coverArrives,
  );

  @override
  List<Object?> get props => <Object?>[
    initials,
    classroomName,
    shiftStart,
    signedInAt,
    signedOutAt,
    isInsideGeofence,
    isCheckingLocation,
    coverName,
    coverArrives,
  ];
}
