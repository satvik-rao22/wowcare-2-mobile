part of 'kiosk_attendance_cubit_v2.dart';

/// Base state for kiosk attendance using MVVM + Clean Architecture.
/// Immutable states allow proper equality comparison and BlocListener reactions.
abstract class KioskAttendanceStateV2 extends Equatable {
  const KioskAttendanceStateV2();

  @override
  List<Object?> get props => [];
}

/// Initial state - ready for operations.
class KioskAttendanceInitialV2 extends KioskAttendanceStateV2 {
  const KioskAttendanceInitialV2();
}

/// Loading state - API call in progress.
class KioskAttendanceSubmittingV2 extends KioskAttendanceStateV2 {
  const KioskAttendanceSubmittingV2();
}

/// Success state - attendance operation completed successfully.
/// Contains all necessary data for UI rendering without additional lookups.
class KioskAttendanceSuccessV2 extends KioskAttendanceStateV2 {
  const KioskAttendanceSuccessV2({
    required this.message,
    required this.action, // 'SIGN_IN' or 'SIGN_OUT'
    required this.role, // 'STAFF' or 'GUARDIAN'
    required this.staffCode,
    required this.status, // 'SIGNED_IN' or 'SIGNED_OUT'
  });

  final String message;
  final String action;
  final String role;
  final String staffCode;
  final String status;

  @override
  List<Object?> get props => [message, action, role, staffCode, status];
}

/// Error state - attendance operation failed.
class KioskAttendanceErrorV2 extends KioskAttendanceStateV2 {
  const KioskAttendanceErrorV2(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
