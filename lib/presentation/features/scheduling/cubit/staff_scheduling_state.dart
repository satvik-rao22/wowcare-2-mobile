import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../model/staff_model.dart';

abstract class StaffSchedulingState {}

class StaffSchedulingInitial extends StaffSchedulingState {}

class StaffSchedulingLoaded extends StaffSchedulingState {
  final bool expandAll;
  final String? selectedClassroom;
  final String? selectedPublish;
  final List<StaffModel> staffList;
  final List<StaffShiftEntity> staffShifts;
  final List<Map<String, dynamic>> allClassrooms;

  /// ✅ NEW
  final Map<String, bool> expandedMap;
  final Map<String, int?> activeMessageMap;
  final bool isDailyView;
  final DateTime? selectedDate;

  StaffSchedulingLoaded({
    required this.expandAll,
    required this.staffList,
    this.staffShifts = const [],
    this.allClassrooms = const [],
    this.selectedClassroom,
    this.selectedPublish,
    this.expandedMap = const {},
    this.activeMessageMap = const {},
    this.isDailyView = false,
    this.selectedDate,
  });

  StaffSchedulingLoaded copyWith({
    bool? expandAll,
    String? selectedClassroom,
    String? selectedPublish,
    List<StaffModel>? staffList,
    List<StaffShiftEntity>? staffShifts,
    List<Map<String, dynamic>>? allClassrooms,
    Map<String, bool>? expandedMap,
    Map<String, int?>? activeMessageMap,
    bool? isDailyView,
    DateTime? selectedDate,
  }) {
    return StaffSchedulingLoaded(
      expandAll: expandAll ?? this.expandAll,
      staffList: staffList ?? this.staffList,
      staffShifts: staffShifts ?? this.staffShifts,
      allClassrooms: allClassrooms ?? this.allClassrooms,
      selectedClassroom: selectedClassroom ?? this.selectedClassroom,
      selectedPublish: selectedPublish ?? this.selectedPublish,
      expandedMap: expandedMap ?? this.expandedMap,
      activeMessageMap: activeMessageMap ?? this.activeMessageMap,
      isDailyView: isDailyView ?? this.isDailyView,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}
