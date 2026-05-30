part of 'date_range_cubit.dart';

class DateRangeState extends Equatable {
  const DateRangeState({required this.startDate, required this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}
