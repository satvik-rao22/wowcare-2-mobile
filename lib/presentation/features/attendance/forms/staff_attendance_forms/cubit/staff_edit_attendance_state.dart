part of 'staff_edit_attendance_cubit.dart';

/// Immutable form state for [StaffEditAttendanceFormCubit].
class StaffEditAttendanceState extends Equatable {
  const StaffEditAttendanceState({
    this.signInTime,
    this.signOutTime,
    this.schoolIana = SchoolTimezoneResolver.fallbackTimeZone,
    this.isSubmitting = false,
  });

  /// Currently selected sign-in time (null until prefilled / picked).
  final TimeOfDay? signInTime;

  /// Currently selected sign-out time (null when not yet signed out).
  final TimeOfDay? signOutTime;

  /// Resolved school IANA timezone; defaults to the resolver's fallback.
  final String schoolIana;

  /// Whether a submission is currently in flight.
  final bool isSubmitting;

  StaffEditAttendanceState copyWith({
    TimeOfDay? signInTime,
    TimeOfDay? signOutTime,
    String? schoolIana,
    bool? isSubmitting,
  }) {
    return StaffEditAttendanceState(
      signInTime: signInTime ?? this.signInTime,
      signOutTime: signOutTime ?? this.signOutTime,
      schoolIana: schoolIana ?? this.schoolIana,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [signInTime, signOutTime, schoolIana, isSubmitting];
}
