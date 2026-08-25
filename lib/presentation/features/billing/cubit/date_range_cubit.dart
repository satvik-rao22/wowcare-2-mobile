import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'date_range_state.dart';

/// Small cubit holding a start/end date range for the accounting date-range
/// selector widget.
class DateRangeCubit extends Cubit<DateRangeState> {
  DateRangeCubit({DateTime? start, DateTime? end})
    : super(DateRangeState(startDate: start, endDate: end));

  void setRange(DateTime? start, DateTime? end) {
    emit(DateRangeState(startDate: start, endDate: end));
  }
}
