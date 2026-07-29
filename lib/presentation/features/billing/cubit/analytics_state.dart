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

  /// Returns the effective year to use for data fetches — defaults to the
  /// current year in the SCHOOL calendar when [selectedYear] is null (the
  /// initial state), so a device in another zone can't request the wrong year
  /// across a New Year boundary.
  int get effectiveYear => selectedYear ?? billingSchoolCurrentYear();

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
