import '../model/staff_model.dart';

abstract class StaffSchedulingState {}

class StaffSchedulingInitial extends StaffSchedulingState {}

class StaffSchedulingLoaded extends StaffSchedulingState {
  final bool expandAll;
  final String? selectedClassroom;
  final String? selectedPublish;
  final List<StaffModel> staffList;

  /// ✅ NEW
  final Map<String, bool> expandedMap;
  final Map<String, int?> activeMessageMap;

  StaffSchedulingLoaded({
    required this.expandAll,
    required this.staffList,
    this.selectedClassroom,
    this.selectedPublish,
    this.expandedMap = const {},
    this.activeMessageMap = const {},
  });

  StaffSchedulingLoaded copyWith({
    bool? expandAll,
    String? selectedClassroom,
    String? selectedPublish,
    List<StaffModel>? staffList,
    Map<String, bool>? expandedMap,
    Map<String, int?>? activeMessageMap,
  }) {
    return StaffSchedulingLoaded(
      expandAll: expandAll ?? this.expandAll,
      staffList: staffList ?? this.staffList,
      selectedClassroom: selectedClassroom ?? this.selectedClassroom,
      selectedPublish: selectedPublish ?? this.selectedPublish,
      expandedMap: expandedMap ?? this.expandedMap,
      activeMessageMap: activeMessageMap ?? this.activeMessageMap,
    );
  }
}
