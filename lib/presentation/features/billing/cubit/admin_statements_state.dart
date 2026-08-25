part of 'admin_statements_cubit.dart';

class AdminStatementsState extends Equatable {
  const AdminStatementsState({
    required this.isLoading,
    required this.statements,
    required this.errorMessage,
    required this.downloadingCodes,
    required this.isGenerating,
    required this.generateError,
    this.customStartDate,
    this.customEndDate,
  });

  const AdminStatementsState.initial()
    : isLoading = false,
      statements = const [],
      errorMessage = '',
      downloadingCodes = const {},
      isGenerating = false,
      generateError = '',
      customStartDate = null,
      customEndDate = null;

  final bool isLoading;
  final List<BillingStatementEntity> statements;
  final String errorMessage;

  /// Codes of statements currently being downloaded.
  final Set<String> downloadingCodes;

  final bool isGenerating;
  final String generateError;

  final DateTime? customStartDate;
  final DateTime? customEndDate;

  bool isDownloading(String code) => downloadingCodes.contains(code);

  List<BillingStatementEntity> get filteredStatements {
    if (customStartDate == null || customEndDate == null) return statements;
    return statements.where((s) {
      return !s.periodStart.isAfter(customEndDate!) &&
          !s.periodEnd.isBefore(customStartDate!);
    }).toList();
  }

  AdminStatementsState copyWith({
    bool? isLoading,
    List<BillingStatementEntity>? statements,
    String? errorMessage,
    Set<String>? downloadingCodes,
    bool? isGenerating,
    String? generateError,
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
  }) {
    return AdminStatementsState(
      isLoading: isLoading ?? this.isLoading,
      statements: statements ?? this.statements,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadingCodes: downloadingCodes ?? this.downloadingCodes,
      isGenerating: isGenerating ?? this.isGenerating,
      generateError: generateError ?? this.generateError,
      customStartDate: customStartDate != null
          ? customStartDate()
          : this.customStartDate,
      customEndDate: customEndDate != null
          ? customEndDate()
          : this.customEndDate,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    statements,
    errorMessage,
    downloadingCodes,
    isGenerating,
    generateError,
    customStartDate,
    customEndDate,
  ];
}
