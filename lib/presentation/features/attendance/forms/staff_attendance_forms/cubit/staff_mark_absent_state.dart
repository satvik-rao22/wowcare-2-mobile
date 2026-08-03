part of 'staff_mark_absent_cubit.dart';

/// Immutable form state for [StaffMarkAbsentFormCubit].
class StaffMarkAbsentState extends Equatable {
  const StaffMarkAbsentState({
    required this.selectedStaff,
    required this.startDate,
    required this.endDate,
    this.schoolIana,
    this.isStaffAdminPersona,
    this.currentStaffCode,
    this.isSubmitting = false,
  });

  factory StaffMarkAbsentState.initial() {
    final now = ServerTimeService.instance.now();
    final today = DateTime(now.year, now.month, now.day);
    return StaffMarkAbsentState(
      selectedStaff: const <StaffEntity>[],
      startDate: today,
      endDate: today,
    );
  }

  /// Working list of staff to mark absent (staff can be removed).
  final List<StaffEntity> selectedStaff;

  /// Absence start date, clamped to the school calendar's "today".
  final DateTime startDate;

  /// Absence end date, never before [startDate] and not after today.
  final DateTime endDate;

  /// Resolved school IANA timezone, or null if it could not be resolved.
  final String? schoolIana;

  /// Whether the signed-in user is an admin persona (gates date editing /
  /// marking others absent). Null until the persona flags finish loading.
  final bool? isStaffAdminPersona;

  /// The logged-in user's own staff code, used to detect when [selectedStaff]
  /// is actually their own record (self attendance never allows date editing,
  /// even for an admin persona).
  final String? currentStaffCode;

  /// Whether a submission is currently in flight.
  final bool isSubmitting;

  /// True when this form targets the logged-in user's own attendance record
  /// (My Attendance) rather than another staff member's. Self attendance can
  /// never have its date range edited, even by an admin persona — only
  /// admin-managed OTHER-staff attendance allows picking dates.
  bool get isSelfTarget {
    final code = currentStaffCode;
    if (code == null || code.isEmpty) return false;
    return selectedStaff.length == 1 &&
        (selectedStaff.first.staffCode ?? '').trim() == code;
  }

  StaffMarkAbsentState copyWith({
    List<StaffEntity>? selectedStaff,
    DateTime? startDate,
    DateTime? endDate,
    String? schoolIana,
    bool? isStaffAdminPersona,
    String? currentStaffCode,
    bool? isSubmitting,
  }) {
    return StaffMarkAbsentState(
      selectedStaff: selectedStaff ?? this.selectedStaff,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schoolIana: schoolIana ?? this.schoolIana,
      isStaffAdminPersona: isStaffAdminPersona ?? this.isStaffAdminPersona,
      currentStaffCode: currentStaffCode ?? this.currentStaffCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        selectedStaff,
        startDate,
        endDate,
        schoolIana,
        isStaffAdminPersona,
        currentStaffCode,
        isSubmitting,
      ];
}
