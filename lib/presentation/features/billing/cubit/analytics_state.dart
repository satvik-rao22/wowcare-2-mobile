part of 'analytics_cubit.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    required this.isLoading,
    required this.selectedYear,
    this.analytics,
    this.errorMessage,
  });

  const AnalyticsState.initial()
      : this(
          isLoading: false,
          selectedYear: null,
          analytics: null,
          errorMessage: null,
        );

  final bool isLoading;
  final int? selectedYear;
  final InvoiceAnalyticsEntity? analytics;
  final String? errorMessage;

  AnalyticsState copyWith({
    bool? isLoading,
    int? Function()? selectedYear,
    InvoiceAnalyticsEntity? Function()? analytics,
    String? Function()? errorMessage,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      selectedYear:
          selectedYear != null ? selectedYear() : this.selectedYear,
      analytics: analytics != null ? analytics() : this.analytics,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, selectedYear, analytics, errorMessage];
}
