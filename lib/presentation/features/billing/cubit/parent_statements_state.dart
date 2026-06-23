part of 'parent_statements_cubit.dart';

class ParentStatementsState extends Equatable {
  const ParentStatementsState({
    required this.customStartDate,
    required this.customEndDate,
    required this.isStatementsLoading,
    required this.isGenerating,
    required this.displayCount,
  });

  const ParentStatementsState.initial()
      : customStartDate = null,
        customEndDate = null,
        isStatementsLoading = false,
        isGenerating = false,
        displayCount = 10;

  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isStatementsLoading;
  final bool isGenerating;

  /// How many statements to show (client-side pagination).
  final int displayCount;

  bool get hasDateRange => customStartDate != null && customEndDate != null;

  List<DemoStatement> get demoStatements {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    return [
      DemoStatement(
        id: 'st_001',
        studentName: 'Lux Stud',
        statementType: 'Yearly',
        generatedOn: DateTime(currentYear, 1, 22),
        periodFrom: DateTime(currentYear, 1, 1),
        periodTo: DateTime(currentYear, 12, 31),
      ),
      DemoStatement(
        id: 'st_002',
        studentName: 'Lux Stud',
        statementType: 'Monthly',
        generatedOn: DateTime(currentYear, currentMonth, 15),
        periodFrom: DateTime(currentYear, currentMonth, 1),
        periodTo: DateTime(currentYear, currentMonth + 1, 0),
      ),
      DemoStatement(
        id: 'st_003',
        studentName: 'Lux Stud',
        statementType: 'Monthly',
        generatedOn: DateTime(currentYear, currentMonth - 1, 20),
        periodFrom: DateTime(currentYear, currentMonth - 1, 1),
        periodTo: DateTime(currentYear, currentMonth, 0),
      ),
      DemoStatement(
        id: 'st_004',
        studentName: 'Lux Stud',
        statementType: 'Quarterly',
        generatedOn: DateTime(currentYear, currentMonth, 10),
        periodFrom: DateTime(currentYear, currentMonth - 2, 1),
        periodTo: DateTime(currentYear, currentMonth, 0),
      ),
    ];
  }

  List<DemoStatement> get filteredStatements {
    final all = demoStatements;
    if (hasDateRange) {
      final selectedStart = DateTime(
          customStartDate!.year, customStartDate!.month, customStartDate!.day);
      final selectedEnd = DateTime(
          customEndDate!.year, customEndDate!.month, customEndDate!.day);
      return all.where((stmt) {
        final stmtStart = DateTime(
            stmt.periodFrom.year, stmt.periodFrom.month, stmt.periodFrom.day);
        final stmtEnd =
            DateTime(stmt.periodTo.year, stmt.periodTo.month, stmt.periodTo.day);
        return stmtStart.isBefore(selectedEnd.add(const Duration(days: 1))) &&
            stmtEnd.isAfter(selectedStart.subtract(const Duration(days: 1)));
      }).toList()
        ..sort((a, b) => b.generatedOn.compareTo(a.generatedOn));
    }
    return List.from(all)
      ..sort((a, b) => b.generatedOn.compareTo(a.generatedOn));
  }

  /// Statements visible in the current page window.
  List<DemoStatement> get visibleStatements =>
      filteredStatements.take(displayCount).toList();

  /// Whether there are more statements beyond the current page window.
  bool get hasMoreStatements => filteredStatements.length > displayCount;

  ParentStatementsState copyWith({
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
    bool? isStatementsLoading,
    bool? isGenerating,
    int? displayCount,
  }) {
    return ParentStatementsState(
      customStartDate:
          customStartDate != null ? customStartDate() : this.customStartDate,
      customEndDate:
          customEndDate != null ? customEndDate() : this.customEndDate,
      isStatementsLoading: isStatementsLoading ?? this.isStatementsLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      displayCount: displayCount ?? this.displayCount,
    );
  }

  @override
  List<Object?> get props =>
      [customStartDate, customEndDate, isStatementsLoading, isGenerating, displayCount];
}
