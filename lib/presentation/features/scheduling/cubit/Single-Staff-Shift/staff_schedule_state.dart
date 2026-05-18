import 'package:equatable/equatable.dart';
import '../../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

class StaffScheduleState extends Equatable {
  final bool isLoadingStaff;
  final bool isLoadingSchedule;

  final String? staffError;
  final String? scheduleError;

  final List<StaffMember> staffList;

  final StaffMember? selectedStaff;

  final StaffProfile? selectedProfile;

  final List<StaffShiftEntity> shifts;

  final Map<String, String> classroomMap;

  const StaffScheduleState({
    this.isLoadingStaff = false,
    this.isLoadingSchedule = false,
    this.staffError,
    this.scheduleError,
    this.staffList = const [],
    this.selectedStaff,
    this.selectedProfile,
    this.shifts = const [],
    this.classroomMap = const {},
  });

  StaffScheduleState copyWith({
    bool? isLoadingStaff,
    bool? isLoadingSchedule,
    String? staffError,
    String? scheduleError,
    List<StaffMember>? staffList,
    StaffMember? selectedStaff,
    StaffProfile? selectedProfile,
    List<StaffShiftEntity>? shifts,
    Map<String, String>? classroomMap,
  }) {
    return StaffScheduleState(
      isLoadingStaff: isLoadingStaff ?? this.isLoadingStaff,

      isLoadingSchedule: isLoadingSchedule ?? this.isLoadingSchedule,

      staffError: staffError,

      scheduleError: scheduleError,

      staffList: staffList ?? this.staffList,

      selectedStaff: selectedStaff ?? this.selectedStaff,

      selectedProfile: selectedProfile ?? this.selectedProfile,

      shifts: shifts ?? this.shifts,

      classroomMap: classroomMap ?? this.classroomMap,
    );
  }

  @override
  List<Object?> get props => [
    isLoadingStaff,
    isLoadingSchedule,
    staffError,
    scheduleError,
    staffList,
    selectedStaff,
    selectedProfile,
    shifts,
    classroomMap,
  ];
}
