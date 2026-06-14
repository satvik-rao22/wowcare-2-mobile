part of 'kiosk_attendance_cubit.dart';

/// State for Kiosk Attendance operations (sign-in/sign-out for staff and students).
abstract class KioskAttendanceState extends Equatable {
  const KioskAttendanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state - ready for sign-in/sign-out
class KioskAttendanceInitial extends KioskAttendanceState {
  const KioskAttendanceInitial();
}

/// Submitting sign-in/sign-out request to API
class KioskAttendanceSubmitting extends KioskAttendanceState {
  const KioskAttendanceSubmitting();
}

/// Successfully submitted sign-in/sign-out
class KioskAttendanceSuccess extends KioskAttendanceState {
  const KioskAttendanceSuccess({
    required this.message,
    required this.action,
    required this.role,
    this.status,
  });

  final String message;
  final String action; // 'SIGN_IN' or 'SIGN_OUT'
  final String role; // 'STAFF' or 'GUARDIAN'
  final String? status; // e.g., 'SIGNED_IN' from status API

  @override
  List<Object?> get props => [message, action, role, status];
}

/// Error occurred during sign-in/sign-out
class KioskAttendanceError extends KioskAttendanceState {
  const KioskAttendanceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
