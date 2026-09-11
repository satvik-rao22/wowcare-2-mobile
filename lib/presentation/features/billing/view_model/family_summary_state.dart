part of 'family_summary_cubit.dart';

class FamilySummaryState extends Equatable {
  const FamilySummaryState({
    required this.families,
    required this.searchQuery,
    required this.showOutstandingOnly,
    required this.invoiceStatuses,
    required this.paymentMethods,
    required this.isLoading,
    this.errorMessage,
  });

  const FamilySummaryState.initial()
      : families = const <FamilySummaryEntity>[],
        searchQuery = '',
        showOutstandingOnly = false,
        invoiceStatuses = const <String>{},
        paymentMethods = const <String>{},
        isLoading = true,
        errorMessage = null;

  final List<FamilySummaryEntity> families;
  final String searchQuery;
  final bool showOutstandingOnly;

  /// Filter selections from the funnel sheet, normalised to trimmed upper
  /// case. Empty means "no restriction", NOT "match nothing".
  final Set<String> invoiceStatuses;
  final Set<String> paymentMethods;

  final bool isLoading;
  final String? errorMessage;

  /// True when the funnel sheet has narrowed the list — drives the marker on
  /// the filter button so an applied filter stays visible after it closes.
  bool get hasActiveFilters =>
      invoiceStatuses.isNotEmpty || paymentMethods.isNotEmpty;

  /// Options for the filter sheet, taken from the rows actually loaded rather
  /// than a hardcoded enum: the backend's status/method vocabularies aren't
  /// published to the client, so this can neither offer values a school never
  /// uses nor miss ones the backend adds later.
  List<String> get availableInvoiceStatuses =>
      _distinctValues((f) => f.lastInvoiceStatus);

  List<String> get availablePaymentMethods =>
      _distinctValues((f) => f.lastPaymentMethod);

  List<String> _distinctValues(String Function(FamilySummaryEntity) pick) {
    final values = families
        .where((f) => f.hasTransactions)
        .map((f) => _normalize(pick(f)))
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  static String _normalize(String value) => value.trim().toUpperCase();

  bool _matchesFilters(FamilySummaryEntity f) {
    if (invoiceStatuses.isNotEmpty &&
        !invoiceStatuses.contains(_normalize(f.lastInvoiceStatus))) {
      return false;
    }
    if (paymentMethods.isNotEmpty &&
        !paymentMethods.contains(_normalize(f.lastPaymentMethod))) {
      return false;
    }
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
    Set<String>? invoiceStatuses,
    Set<String>? paymentMethods,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FamilySummaryState(
      families: families ?? this.families,
      searchQuery: searchQuery ?? this.searchQuery,
      showOutstandingOnly: showOutstandingOnly ?? this.showOutstandingOnly,
      invoiceStatuses: invoiceStatuses ?? this.invoiceStatuses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        families,
        searchQuery,
        showOutstandingOnly,
        invoiceStatuses,
        paymentMethods,
        isLoading,
        errorMessage,
      ];
}
