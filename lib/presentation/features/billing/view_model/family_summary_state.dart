part of 'family_summary_cubit.dart';

class FamilySummaryState extends Equatable {
  const FamilySummaryState({
    required this.families,
    required this.searchQuery,
    required this.showOutstandingOnly,
    required this.classroomNames,
    required this.classroomNameToCode,
    required this.tagNames,
    required this.tagNameToCode,
    required this.selectedClassroomNames,
    required this.selectedTagNames,
    required this.selectedStatus,
    required this.matchingStudentCodes,
    required this.isLoading,
    this.isApplyingFilters = false,
    this.errorMessage,
  });

  const FamilySummaryState.initial()
      : families = const <FamilySummaryEntity>[],
        searchQuery = '',
        showOutstandingOnly = false,
        classroomNames = const <String>[],
        classroomNameToCode = const <String, String>{},
        tagNames = const <String>[],
        tagNameToCode = const <String, String>{},
        selectedClassroomNames = const <String>[],
        selectedTagNames = const <String>[],
        selectedStatus = null,
        matchingStudentCodes = null,
        isLoading = true,
        isApplyingFilters = false,
        errorMessage = null;

  final List<FamilySummaryEntity> families;
  final String searchQuery;
  final bool showOutstandingOnly;

  /// Funnel-sheet option data for the student-side facets, loaded from the
  /// classroom and tag APIs. The name→code maps translate the display names
  /// the sheet works in into the codes the student list API expects.
  final List<String> classroomNames;
  final Map<String, String> classroomNameToCode;
  final List<String> tagNames;
  final Map<String, String> tagNameToCode;

  /// Student-side selections, held as display names (the sheet's vocabulary).
  final List<String> selectedClassroomNames;
  final List<String> selectedTagNames;

  /// Single-select student status — `Active` / `Inactive` / `Upcoming`, or
  /// null for no restriction.
  final String? selectedStatus;

  /// Codes returned by the student list API for the current classroom / tag /
  /// status selection, or null when no student-side facet is applied.
  ///
  /// null and empty mean different things: null is "no restriction", while an
  /// empty set is a real result — no student matched, so no family should.
  final Set<String>? matchingStudentCodes;

  final bool isLoading;

  /// True while the student-code lookup behind a classroom/tag/status
  /// selection is in flight.
  final bool isApplyingFilters;

  final String? errorMessage;

  /// True when the funnel sheet has narrowed the list — drives the marker on
  /// the filter button so an applied filter stays visible after it closes.
  bool get hasActiveFilters =>
      selectedClassroomNames.isNotEmpty ||
      selectedTagNames.isNotEmpty ||
      (selectedStatus ?? '').isNotEmpty;

  bool _matchesFilters(FamilySummaryEntity f) {
    // Classroom / tag / status resolve to a set of student codes; a family
    // matches when any of its students is in that set. A row with no student
    // codes therefore can't match a student-side filter — correct, since
    // nothing ties it to the selected classroom, tag or status.
    final codes = matchingStudentCodes;
    if (codes != null && !f.studentCodes.any(codes.contains)) return false;
    return true;
  }

  bool _matchesSearch(FamilySummaryEntity f) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return f.familyName.toLowerCase().contains(q) ||
        f.guardianName.toLowerCase().contains(q);
  }

  /// Client-side search (family / guardian name) + the outstanding toggle +
  /// the funnel filters.
  List<FamilySummaryEntity> get filteredFamilies {
    return families.where((f) {
      if (!f.hasTransactions) return false;
      if (showOutstandingOnly && f.openBalance <= 0) return false;
      if (!_matchesFilters(f)) return false;
      return _matchesSearch(f);
    }).toList();
  }

  /// Sum of open balances across the search- and filter-matched families, so
  /// the figure beside the toggle describes the list on screen. The
  /// outstanding toggle itself is excluded — it can only drop zero-balance
  /// rows, which contribute nothing to the sum.
  double get totalOutstanding => families
      .where((f) => f.hasTransactions && _matchesFilters(f) && _matchesSearch(f))
      .fold<double>(0, (sum, f) => sum + f.openBalance);

  FamilySummaryState copyWith({
    List<FamilySummaryEntity>? families,
    String? searchQuery,
    bool? showOutstandingOnly,
    List<String>? classroomNames,
    Map<String, String>? classroomNameToCode,
    List<String>? tagNames,
    Map<String, String>? tagNameToCode,
    List<String>? selectedClassroomNames,
    List<String>? selectedTagNames,
    // Closure-wrapped so null can be set explicitly (clearing the facet)
    // rather than meaning "unchanged".
    String? Function()? selectedStatus,
    Set<String>? Function()? matchingStudentCodes,
    bool? isLoading,
    bool? isApplyingFilters,
    String? errorMessage,
  }) {
    return FamilySummaryState(
      families: families ?? this.families,
      searchQuery: searchQuery ?? this.searchQuery,
      showOutstandingOnly: showOutstandingOnly ?? this.showOutstandingOnly,
      classroomNames: classroomNames ?? this.classroomNames,
      classroomNameToCode: classroomNameToCode ?? this.classroomNameToCode,
      tagNames: tagNames ?? this.tagNames,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      selectedClassroomNames:
          selectedClassroomNames ?? this.selectedClassroomNames,
      selectedTagNames: selectedTagNames ?? this.selectedTagNames,
      selectedStatus:
          selectedStatus != null ? selectedStatus() : this.selectedStatus,
      matchingStudentCodes: matchingStudentCodes != null
          ? matchingStudentCodes()
          : this.matchingStudentCodes,
      isLoading: isLoading ?? this.isLoading,
      isApplyingFilters: isApplyingFilters ?? this.isApplyingFilters,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        families,
        searchQuery,
        showOutstandingOnly,
        classroomNames,
        classroomNameToCode,
        tagNames,
        tagNameToCode,
        selectedClassroomNames,
        selectedTagNames,
        selectedStatus,
        matchingStudentCodes,
        isLoading,
        isApplyingFilters,
        errorMessage,
      ];
}
