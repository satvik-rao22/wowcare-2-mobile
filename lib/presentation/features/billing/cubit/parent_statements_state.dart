part of 'parent_statements_cubit.dart';

class ParentStatementsState extends Equatable {
  const ParentStatementsState({
    required this.customStartDate,
    required this.customEndDate,
    required this.isStatementsLoading,
    required this.isGenerating,
    required this.displayCount,
    required this.statements,
    required this.downloadingCodes,
    required this.errorMessage,
  });

  const ParentStatementsState.initial()
      : customStartDate = null,
        customEndDate = null,
        isStatementsLoading = false,
        isGenerating = false,
        displayCount = 10,
        statements = const [],
        downloadingCodes = const {},
        errorMessage = '';

  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isStatementsLoading;
  final bool isGenerating;

  /// How many statements to show (client-side pagination).
  final int displayCount;

  /// The guardian's statements from the API.
  final List<BillingStatementEntity> statements;

  /// Statement codes whose PDF is currently downloading.
  final Set<String> downloadingCodes;

  final String errorMessage;

  bool get hasDateRange => customStartDate != null && customEndDate != null;

  bool isDownloading(String code) => downloadingCodes.contains(code);

  /// Statements within the selected date range, newest first.
  List<BillingStatementEntity> get filteredStatements {
    final all = List<BillingStatementEntity>.from(statements);
    Iterable<BillingStatementEntity> result = all;
    if (hasDateRange) {
      final selectedStart = DateTime(
          customStartDate!.year, customStartDate!.month, customStartDate!.day);
      final selectedEnd = DateTime(
          customEndDate!.year, customEndDate!.month, customEndDate!.day);
      result = all.where((stmt) {
        final stmtStart = DateTime(stmt.periodStart.year, stmt.periodStart.month,
            stmt.periodStart.day);
        final stmtEnd =
            DateTime(stmt.periodEnd.year, stmt.periodEnd.month, stmt.periodEnd.day);
        return stmtStart.isBefore(selectedEnd.add(const Duration(days: 1))) &&
            stmtEnd.isAfter(selectedStart.subtract(const Duration(days: 1)));
      });
    }
    final list = result.toList()
      ..sort((a, b) {
        final ad = a.generatedAt;
        final bd = b.generatedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    return list;
  }

  /// Statements visible in the current page window.
  List<BillingStatementEntity> get visibleStatements =>
      filteredStatements.take(displayCount).toList();

  /// Whether there are more statements beyond the current page window.
  bool get hasMoreStatements => filteredStatements.length > displayCount;

  ParentStatementsState copyWith({
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
    bool? isStatementsLoading,
    bool? isGenerating,
    int? displayCount,
    List<BillingStatementEntity>? statements,
    Set<String>? downloadingCodes,
    String? Function()? errorMessage,
  }) {
    return ParentStatementsState(
      customStartDate:
          customStartDate != null ? customStartDate() : this.customStartDate,
      customEndDate:
          customEndDate != null ? customEndDate() : this.customEndDate,
      isStatementsLoading: isStatementsLoading ?? this.isStatementsLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      displayCount: displayCount ?? this.displayCount,
      statements: statements ?? this.statements,
      downloadingCodes: downloadingCodes ?? this.downloadingCodes,
      errorMessage:
          errorMessage != null ? (errorMessage() ?? '') : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        customStartDate,
        customEndDate,
        isStatementsLoading,
        isGenerating,
        displayCount,
        statements,
        downloadingCodes,
        errorMessage,
      ];
}
