import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';
import '../../staff/widgets/staff_attendance_action_availability.dart';

class AssignStaffSelectionState extends Equatable {
  const AssignStaffSelectionState({
    this.allStaff = const [],
    this.rooms = const [],
    this.designations = const [],
    this.selectedClassroom,
    this.selectedDesignations = const [],
    this.searchText = '',
    this.selectedStaff = const {},
    this.todayStatusByCode = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StaffClassroomItem> allStaff;

  /// Classroom display names for the Classroom filter dropdown.
  final List<String> rooms;

  /// Designation display labels for the Designation multi-select.
  final List<String> designations;

  final String? selectedClassroom;
  final List<String> selectedDesignations;
  final String searchText;
  final Set<StaffClassroomItem> selectedStaff;

  /// Today's sign-in status per staff code.
  final Map<String, String> todayStatusByCode;

  final bool isLoading;
  final String? errorMessage;

  /// [allStaff] is already scoped server-side by Classroom/Designation; this
  /// applies the client-side free-text search only.
  List<StaffClassroomItem> get visibleStaff {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return allStaff;
    return allStaff
        .where((staff) => staff.fullName.toLowerCase().contains(query))
        .toList();
  }

  bool isStaffSignedIn(String staffCode) {
    final gate = staffAttendanceGateFromTodayStatus(
      isActiveProfile: true,
      todayStatusRaw: todayStatusByCode[staffCode],
    );
    return gate.isSignedInToday;
  }

  bool get isSelectAllChecked {
    final selectable = visibleStaff.where((s) => !isStaffSignedIn(s.staffCode));
    return selectable.isNotEmpty &&
        selectable.every((s) => selectedStaff.contains(s));
  }

  AssignStaffSelectionState copyWith({
    List<StaffClassroomItem>? allStaff,
    List<String>? rooms,
    List<String>? designations,
    String? selectedClassroom,
    List<String>? selectedDesignations,
    String? searchText,
    Set<StaffClassroomItem>? selectedStaff,
    Map<String, String>? todayStatusByCode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AssignStaffSelectionState(
      allStaff: allStaff ?? this.allStaff,
      rooms: rooms ?? this.rooms,
      designations: designations ?? this.designations,
      selectedClassroom: selectedClassroom ?? this.selectedClassroom,
      selectedDesignations: selectedDesignations ?? this.selectedDesignations,
      searchText: searchText ?? this.searchText,
      selectedStaff: selectedStaff ?? this.selectedStaff,
      todayStatusByCode: todayStatusByCode ?? this.todayStatusByCode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allStaff,
    rooms,
    designations,
    selectedClassroom,
    selectedDesignations,
    searchText,
    selectedStaff,
    todayStatusByCode,
    isLoading,
    errorMessage,
  ];
}
