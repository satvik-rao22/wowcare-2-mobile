part of 'family_summary_cubit.dart';

class FamilySummaryState extends Equatable {
  const FamilySummaryState({
    required this.families,
    required this.searchQuery,
    required this.showOutstandingOnly,
    required this.isLoading,
    this.errorMessage,
  });

  const FamilySummaryState.initial()
    : families = const <FamilySummaryEntity>[],
      searchQuery = '',
      showOutstandingOnly = false,
      isLoading = true,
      errorMessage = null;

  final List<FamilySummaryEntity> families;
  final String searchQuery;
  final bool showOutstandingOnly;
  final bool isLoading;
  final String? errorMessage;

  /// Client-side search (family / guardian name) + optional outstanding filter.
  List<FamilySummaryEntity> get filteredFamilies {
    final q = searchQuery.trim().toLowerCase();
    return families.where((f) {
      if (!f.hasTransactions) return false;
      if (showOutstandingOnly && f.openBalance <= 0) return false;
      if (q.isEmpty) return true;
      return f.familyName.toLowerCase().contains(q) ||
          f.guardianName.toLowerCase().contains(q);
    }).toList();
  }

  /// Sum of open balances across the (search-filtered) families.
  double get totalOutstanding {
    final q = searchQuery.trim().toLowerCase();
    return families
        .where(
          (f) =>
              f.hasTransactions &&
              (q.isEmpty ||
                  f.familyName.toLowerCase().contains(q) ||
                  f.guardianName.toLowerCase().contains(q)),
        )
        .fold<double>(0, (sum, f) => sum + f.openBalance);
  }

  FamilySummaryState copyWith({
    List<FamilySummaryEntity>? families,
    String? searchQuery,
    bool? showOutstandingOnly,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FamilySummaryState(
      families: families ?? this.families,
      searchQuery: searchQuery ?? this.searchQuery,
      showOutstandingOnly: showOutstandingOnly ?? this.showOutstandingOnly,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    families,
    searchQuery,
    showOutstandingOnly,
    isLoading,
    errorMessage,
  ];
}
