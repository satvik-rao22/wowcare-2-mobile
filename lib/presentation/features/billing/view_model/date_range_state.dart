part of 'date_range_cubit.dart';

class DateRangeState extends Equatable {
  const DateRangeState({
    required this.startDate,
    required this.endDate,
    this.preset,
  });

  final DateTime? startDate;
  final DateTime? endDate;

  /// Quick-select preset currently shown in the dropdown; null when the range
  /// came from the calendar (or from a reset).
  final BillingQuickRange? preset;

  @override
  List<Object?> get props => [startDate, endDate, preset];
}
