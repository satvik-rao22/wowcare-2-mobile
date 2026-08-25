part of 'staff_scheduling_cubit.dart';

class StaffSchedulingState extends Equatable {
  const StaffSchedulingState({
    required this.selectedDay,
    this.staffList = const [],
    this.selectedStaffCode,
    this.shiftSummary = StaffShiftDaySummary.empty,
    this.schoolStartTime,
    this.schoolEndTime,
    this.hasSchoolHoursForDay = false,
    this.classroomNamesByCode = const {},
    this.isLoadingStaff = false,
    this.isLoadingShifts = false,
    this.isLoadingSchoolHours = false,
    this.hasAttemptedInitialLoad = false,
    this.isStaffPersonaScope = false,
    this.errorMessage,
  });

  final DateTime selectedDay;
  final List<StaffMember> staffList;
  final String? selectedStaffCode;
  final StaffShiftDaySummary shiftSummary;

  /// School open/close for [selectedDay] (`hh:mm:ss a`), from regular-schedule API.
  final String? schoolStartTime;
  final String? schoolEndTime;
  final bool hasSchoolHoursForDay;

  /// Active classroom code → display name for the logged-in school.
  final Map<String, String> classroomNamesByCode;

  final bool isLoadingStaff;
  final bool isLoadingShifts;
  final bool isLoadingSchoolHours;

  /// True once the very first `loadInitial()` has settled (success or failure).
  /// Used by the UI to keep the shimmer up until the first load is done, so we
  /// don't briefly show the "Select a staff member" empty state before the
  /// first emission flips the loading flags on.
  final bool hasAttemptedInitialLoad;

  /// True when the logged-in user is a STAFF persona — the screen narrows the
  /// roster to their own row and hides add/publish/edit/delete actions.
  final bool isStaffPersonaScope;

  final String? errorMessage;

  StaffMember? get selectedStaff {
    final code = selectedStaffCode;
    if (code == null || code.isEmpty) return null;
    for (final s in staffList) {
      if (s.code == code) return s;
    }
    return null;
  }

  ClassroomNameResolver get classroomResolver =>
      ClassroomNameResolver.fromMap(classroomNamesByCode);

  factory StaffSchedulingState.initial() {
    return StaffSchedulingState(selectedDay: schedulingSchoolToday());
  }

  StaffSchedulingState copyWith({
    DateTime? selectedDay,
    List<StaffMember>? staffList,
    String? selectedStaffCode,
    bool clearSelectedStaffCode = false,
    StaffShiftDaySummary? shiftSummary,
    String? schoolStartTime,
    String? schoolEndTime,
    bool? hasSchoolHoursForDay,
    Map<String, String>? classroomNamesByCode,
    bool? isLoadingStaff,
    bool? isLoadingShifts,
    bool? isLoadingSchoolHours,
    bool? hasAttemptedInitialLoad,
    bool? isStaffPersonaScope,
    String? errorMessage,
    bool clearError = false,
    bool clearSchoolHours = false,
  }) {
    return StaffSchedulingState(
      selectedDay: selectedDay ?? this.selectedDay,
      staffList: staffList ?? this.staffList,
      selectedStaffCode: clearSelectedStaffCode
          ? null
          : (selectedStaffCode ?? this.selectedStaffCode),
      shiftSummary: shiftSummary ?? this.shiftSummary,
      schoolStartTime: clearSchoolHours
          ? null
          : (schoolStartTime ?? this.schoolStartTime),
      schoolEndTime: clearSchoolHours
          ? null
          : (schoolEndTime ?? this.schoolEndTime),
      hasSchoolHoursForDay: hasSchoolHoursForDay ?? this.hasSchoolHoursForDay,
      classroomNamesByCode: classroomNamesByCode ?? this.classroomNamesByCode,
      isLoadingStaff: isLoadingStaff ?? this.isLoadingStaff,
      isLoadingShifts: isLoadingShifts ?? this.isLoadingShifts,
      isLoadingSchoolHours: isLoadingSchoolHours ?? this.isLoadingSchoolHours,
      hasAttemptedInitialLoad:
          hasAttemptedInitialLoad ?? this.hasAttemptedInitialLoad,
      isStaffPersonaScope: isStaffPersonaScope ?? this.isStaffPersonaScope,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    selectedDay,
    staffList,
    selectedStaffCode,
    shiftSummary,
    schoolStartTime,
    schoolEndTime,
    hasSchoolHoursForDay,
    classroomNamesByCode,
    isLoadingStaff,
    isLoadingShifts,
    isLoadingSchoolHours,
    hasAttemptedInitialLoad,
    isStaffPersonaScope,
    errorMessage,
  ];
}
