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
    this.isLoadingStaff = false,
    this.isLoadingShifts = false,
    this.isLoadingSchoolHours = false,
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

  final bool isLoadingStaff;
  final bool isLoadingShifts;
  final bool isLoadingSchoolHours;
  final String? errorMessage;

  StaffMember? get selectedStaff {
    final code = selectedStaffCode;
    if (code == null || code.isEmpty) return null;
    for (final s in staffList) {
      if (s.code == code) return s;
    }
    return null;
  }

  List<String> get staffDropdownNames =>
      staffList.map((s) => s.name).toList(growable: false);

  String? get selectedStaffDropdownLabel => selectedStaff?.name;

  factory StaffSchedulingState.initial() {
    final now = DateTime.now();
    return StaffSchedulingState(
      selectedDay: DateTime(now.year, now.month, now.day),
    );
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
    bool? isLoadingStaff,
    bool? isLoadingShifts,
    bool? isLoadingSchoolHours,
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
      schoolStartTime:
          clearSchoolHours ? null : (schoolStartTime ?? this.schoolStartTime),
      schoolEndTime:
          clearSchoolHours ? null : (schoolEndTime ?? this.schoolEndTime),
      hasSchoolHoursForDay:
          hasSchoolHoursForDay ?? this.hasSchoolHoursForDay,
      isLoadingStaff: isLoadingStaff ?? this.isLoadingStaff,
      isLoadingShifts: isLoadingShifts ?? this.isLoadingShifts,
      isLoadingSchoolHours:
          isLoadingSchoolHours ?? this.isLoadingSchoolHours,
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
        isLoadingStaff,
        isLoadingShifts,
        isLoadingSchoolHours,
        errorMessage,
      ];
}
