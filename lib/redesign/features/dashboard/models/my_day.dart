import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// The signed-in staff member's own day (3A1's My day, 3S1's).
///
/// Everything on it comes from calls the app already makes: today's staff
/// attendance row, the shift behind it, and the account's own Sign-In PIN.
@immutable
class MyDay extends Equatable {
  const MyDay({
    required this.status,
    required this.workWindow,
    required this.signInPin,
    this.sinceLabel,
    this.breakWindow,
    this.classroomName,
    this.onClockLabel,
    this.isInsideGeofence = true,
    this.isAbsent = false,
  });

  final AttendanceStatus status;

  /// "7:34 AM". Null before the day starts.
  final String? sinceLabel;

  /// "7:30 – 16:00".
  final String workWindow;

  /// "12:00 – 12:30". Null when the shift carries no break.
  final String? breakWindow;

  /// The four digits the kiosk pad wants.
  final String signInPin;

  /// Attendance actions are gated on this for staff (3S1).
  final bool isInsideGeofence;

  final String? classroomName;

  /// "8h 28m", for the sign-out sheet.
  final String? onClockLabel;

  final bool isAbsent;

  bool get isSignedIn => status == AttendanceStatus.signedIn;

  MyDay copyWith({
    AttendanceStatus? status,
    String? sinceLabel,
    String? classroomName,
    bool? isAbsent,
  }) => MyDay(
    status: status ?? this.status,
    sinceLabel: sinceLabel ?? this.sinceLabel,
    workWindow: workWindow,
    breakWindow: breakWindow,
    signInPin: signInPin,
    isInsideGeofence: isInsideGeofence,
    classroomName: classroomName ?? this.classroomName,
    onClockLabel: onClockLabel,
    isAbsent: isAbsent ?? this.isAbsent,
  );

  @override
  List<Object?> get props => [
    status,
    sinceLabel,
    workWindow,
    breakWindow,
    signInPin,
    isInsideGeofence,
    classroomName,
    onClockLabel,
    isAbsent,
  ];
}
