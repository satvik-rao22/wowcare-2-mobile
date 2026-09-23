part of 'transactions_cubit.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    required this.transactions,
    required this.searchQuery,
    this.overview,
    this.dateFrom,
    this.dateTo,
    this.activeFilter,
    this.selectedType,
    this.selectedStatus,
    this.selectedMode,
    this.selectedPaymentStatus,
    this.selectedStudentStatus,
    this.classroomNames = const <String>[],
    this.classroomNameToCode = const <String, String>{},
    this.tagNames = const <String>[],
    this.tagNameToCode = const <String, String>{},
    this.selectedClassroomNames = const <String>[],
    this.selectedTagNames = const <String>[],
    this.matchingStudentCodes,
    this.isApplyingFilters = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.errorMessage,
    this.successMessage,
  });

  /// Initial state for the Student(s) and Transactions tabs.
  ///
  /// The date range defaults to the current school-calendar month. Both tabs
  /// used to land with a null range, which showed "Select Date Range" and let
  /// the backend apply its own all-time window — so the totals covered a
  /// different period than any range the user later picked. Not `const` for
  /// this reason: the month has to be computed per construction.
  factory TransactionsState.initial() => TransactionsState(
        transactions: const [],
        searchQuery: '',
        dateFrom: billingSchoolMonthStart(),
        dateTo: billingSchoolMonthEnd(),
        isLoading: true,
      );

  final List<TransactionRecord> transactions;
  final String searchQuery;

  /// True during the initial / refresh transactions fetch (drives the shimmer).
  final bool isLoading;

  /// True while the next page is being appended (infinite scroll).
  final bool isLoadingMore;

  /// Whether the backend has more transaction pages after [page].
  final bool hasMore;

  /// Zero-based index of the last loaded transactions page.
  final int page;

  /// Real billing totals from the overview API; null until loaded. When absent
  /// (not loaded yet or the request failed) the stat bar shows zeros.
  final InvoiceOverviewEntity? overview;

  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// The summary-card filter currently scoping the Transactions list, or null
  /// when the unfiltered list is shown. Drives the legend highlight.
  ///
  /// It shares the `type`/`status` query params with the funnel sheet's
  /// [selectedType] (and, historically, [selectedStatus] — now legend-only,
  /// see its own doc), so applying an explicit Type pick clears the legend
  /// (see `TransactionsCubit.applyFilter` and `applyTransactionFilters`).
  /// Otherwise a legend tap and a funnel pick would each silently overwrite
  /// half of the other's query.
  final TransactionFilter? activeFilter;

  /// Funnel-sheet Type selection, held as the display value the sheet works
  /// in ('Invoice', 'Payment', …), or null for no restriction. Single-select:
  /// the endpoint takes one `type`.
  final String? selectedType;

  /// The stat-bar legend's `status` value ('SUCCESS' / 'IN_PROCESS' via
  /// [TransactionFilter.statusParam]) — no longer settable from the funnel
  /// sheet (that field is now [selectedPaymentStatus], a genuinely different
  /// backend facet: the transactions endpoint takes `status` and
  /// `paymentStatus` as two distinct query params).
  final String? selectedStatus;

  /// Funnel-sheet payment-mode selection ('Cash' / 'Check' / 'Online' /
  /// 'Other'), sent verbatim as the `mode` query param, or null for no
  /// restriction.
  final String? selectedMode;

  /// Funnel-sheet Payment Status selection ('Paid' / 'In Progress' /
  /// 'Failed'), sent as the `paymentStatus` query param, or null for no
  /// restriction. Distinct from [selectedStatus] — see its doc.
  final String? selectedPaymentStatus;

  /// Funnel-sheet student-status selection ('Active' / 'Upcoming' /
  /// 'Inactive'), held as the display value, or null for no restriction.
  /// This is a student-enrollment facet resolved the same way as
  /// classroom/tag — through the student list API, intersected against each
  /// row's `studentCode` — not a query param on the transactions endpoint.
  final String? selectedStudentStatus;

  /// Funnel-sheet option data for the student-side facets, loaded from the
  /// classroom and tag APIs.
  final List<String> classroomNames;
  final Map<String, String> classroomNameToCode;
  final List<String> tagNames;
  final Map<String, String> tagNameToCode;

  /// Student-side selections, held as display names.
  final List<String> selectedClassroomNames;
  final List<String> selectedTagNames;

  /// Codes returned by the student list API for the current classroom/tag
  /// selection, or null when neither is applied.
  ///
  /// null and empty mean different things: null is "no restriction", while an
  /// empty set is a real result — no student matched, so no row should.
  final Set<String>? matchingStudentCodes;

  /// True while the student-code lookup behind a classroom/tag pick is in
  /// flight.
  final bool isApplyingFilters;

  /// Last load error, surfaced as a top snackbar by the view.
  final String? errorMessage;

  /// One-shot success message (e.g. after cancel/delete), surfaced as a top
  /// snackbar by the view.
  final String? successMessage;

  /// True when the funnel sheet has narrowed the list — drives the marker on
  /// the filter button so an applied filter stays visible after it closes.
  bool get hasActiveFilters =>
      (selectedType ?? '').isNotEmpty ||
      (selectedMode ?? '').isNotEmpty ||
      (selectedPaymentStatus ?? '').isNotEmpty ||
      (selectedStudentStatus ?? '').isNotEmpty ||
      selectedClassroomNames.isNotEmpty ||
      selectedTagNames.isNotEmpty;

  List<TransactionRecord> get visibleTransactions {
    final query = searchQuery.trim().toLowerCase();
    final codes = matchingStudentCodes;
    return transactions.where((record) {
      final item = record.item;
      // Classroom / tag resolve to a set of student codes. Unlike Type and
      // Status (which the endpoint filters server-side), this narrows only the
      // pages already loaded — the transactions endpoint takes no classroom or
      // tag param, and rows carry a studentCode but no room or tag of their
      // own. A family-level row (payment/refund/credit) has no studentCode, so
      // it can't match a student-side facet.
      if (codes != null) {
        final code = item.studentCode?.trim() ?? '';
        if (code.isEmpty || !codes.contains(code)) return false;
      }
      return query.isEmpty ||
          item.studentName.toLowerCase().contains(query) ||
          item.id.toString().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  // Live overview totals only; zeros when not loaded / on failure (never demo).
  double get totalInvoiced => overview?.amountInvoiced ?? 0;

  // Actual dollar amounts from the overview API (shown verbatim in the cards).
  double get netPaidAmount => overview?.netPaid ?? 0;
  double get paidAmount => overview?.paid ?? 0;
  double get refundedAmount => overview?.refunded ?? 0;
  double get inProcessAmount => overview?.inProcess ?? 0;
  double get outstandingAmount => overview?.outstanding ?? 0;

  /// "Net Paid" share of the invoiced amount.
  double get paidPercent => overview?.netPaidPercent ?? 0;

  /// Gross "Paid" share (before refunds) — shown in the expanded view.
  double get grossPaidPercent => overview?.paidPercent ?? 0;

  double get inProcessPercent => overview?.inProcessPercent ?? 0;

  double get unpaidPercent => overview?.outstandingPercent ?? 0;

  double get refundPercent => overview?.refundedPercent ?? 0;

  TransactionsState copyWith({
    List<TransactionRecord>? transactions,
    String? searchQuery,
    InvoiceOverviewEntity? Function()? overview,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    TransactionFilter? Function()? activeFilter,
    String? Function()? selectedType,
    String? Function()? selectedStatus,
    String? Function()? selectedMode,
    String? Function()? selectedPaymentStatus,
    String? Function()? selectedStudentStatus,
    List<String>? classroomNames,
    Map<String, String>? classroomNameToCode,
    List<String>? tagNames,
    Map<String, String>? tagNameToCode,
    List<String>? selectedClassroomNames,
    List<String>? selectedTagNames,
    Set<String>? Function()? matchingStudentCodes,
    bool? isApplyingFilters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    String? successMessage,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      overview: overview != null ? overview() : this.overview,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      selectedType:
          selectedType != null ? selectedType() : this.selectedType,
      selectedStatus:
          selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedMode: selectedMode != null ? selectedMode() : this.selectedMode,
      selectedPaymentStatus: selectedPaymentStatus != null
          ? selectedPaymentStatus()
          : this.selectedPaymentStatus,
      selectedStudentStatus: selectedStudentStatus != null
          ? selectedStudentStatus()
          : this.selectedStudentStatus,
      classroomNames: classroomNames ?? this.classroomNames,
      classroomNameToCode: classroomNameToCode ?? this.classroomNameToCode,
      tagNames: tagNames ?? this.tagNames,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      selectedClassroomNames:
          selectedClassroomNames ?? this.selectedClassroomNames,
      selectedTagNames: selectedTagNames ?? this.selectedTagNames,
      matchingStudentCodes: matchingStudentCodes != null
          ? matchingStudentCodes()
          : this.matchingStudentCodes,
      isApplyingFilters: isApplyingFilters ?? this.isApplyingFilters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        searchQuery,
        overview,
        dateFrom,
        dateTo,
        activeFilter,
        selectedType,
        selectedStatus,
        selectedMode,
        selectedPaymentStatus,
        selectedStudentStatus,
        classroomNames,
        classroomNameToCode,
        tagNames,
        tagNameToCode,
        selectedClassroomNames,
        selectedTagNames,
        matchingStudentCodes,
        isApplyingFilters,
        isLoading,
        isLoadingMore,
        hasMore,
        page,
        errorMessage,
        successMessage,
      ];
}
