import 'package:equatable/equatable.dart';

/// Selection + filter state for the bulk-messaging recipient picker
/// (`StaffOrStudentSelectionBulkMessaging`). Extracted from the screen's
/// `setState` fields (Mandate 2, Bucket A → cubit).
///
/// This holds only the picker's own state — the filtered roster it selects
/// against comes from `StaffCubit`/`StudentCubit`, and the "select all"
/// checkbox value is *derived* from these selections against that roster (in
/// the view), not stored here.
class RecipientSelectionState extends Equatable {
  const RecipientSelectionState({
    this.selectedClassrooms = const [],
    this.selectedStatus = 'Active',
    this.selectedDesignations = const [],
    this.selectedTags = const [],
    this.selectedStaffCodes = const {},
    this.selectedStudentCodes = const {},
    this.tagOptions = const [],
    this.tagNameToCode = const {},
    this.isSelectingAll = false,
    this.currentStaffCode,
  });

  /// Active filter selections.
  final List<String> selectedClassrooms;
  final String? selectedStatus;
  final List<String> selectedDesignations;
  final List<String> selectedTags;

  /// The picked recipients (only one set is used per screen instance,
  /// depending on `isStaffSelection`).
  final Set<String> selectedStaffCodes;
  final Set<String> selectedStudentCodes;

  /// School tag options + their name→code map, loaded once.
  final List<String> tagOptions;
  final Map<String, String> tagNameToCode;

  /// True while "Select All" is paging in the remaining filtered results.
  final bool isSelectingAll;

  /// The logged-in staff member's own code (excluded from the staff list).
  final String? currentStaffCode;

  RecipientSelectionState copyWith({
    List<String>? selectedClassrooms,
    String? selectedStatus,
    bool clearStatus = false,
    List<String>? selectedDesignations,
    List<String>? selectedTags,
    Set<String>? selectedStaffCodes,
    Set<String>? selectedStudentCodes,
    List<String>? tagOptions,
    Map<String, String>? tagNameToCode,
    bool? isSelectingAll,
    String? currentStaffCode,
  }) {
    return RecipientSelectionState(
      selectedClassrooms: selectedClassrooms ?? this.selectedClassrooms,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedDesignations: selectedDesignations ?? this.selectedDesignations,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedStaffCodes: selectedStaffCodes ?? this.selectedStaffCodes,
      selectedStudentCodes: selectedStudentCodes ?? this.selectedStudentCodes,
      tagOptions: tagOptions ?? this.tagOptions,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      isSelectingAll: isSelectingAll ?? this.isSelectingAll,
      currentStaffCode: currentStaffCode ?? this.currentStaffCode,
    );
  }

  @override
  List<Object?> get props => [
    selectedClassrooms,
    selectedStatus,
    selectedDesignations,
    selectedTags,
    selectedStaffCodes,
    selectedStudentCodes,
    tagOptions,
    tagNameToCode,
    isSelectingAll,
    currentStaffCode,
  ];
}
