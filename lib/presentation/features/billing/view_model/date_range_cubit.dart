import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/presentation/features/billing/model/billing_quick_range.dart';

part 'date_range_state.dart';

/// Small cubit holding a start/end date range for the accounting date-range
/// selector widget, plus the quick-select preset (This week / month / year)
/// that produced it, if any.
///
/// The preset is a view concern only: it tells the dropdown what to show.
/// Picking dates from the calendar clears it, and dates pushed in from the
/// owning screen keep it only while they still match that preset's period.
class DateRangeCubit extends Cubit<DateRangeState> {
  DateRangeCubit({DateTime? start, DateTime? end, BillingQuickRange? preset})
    : super(DateRangeState(startDate: start, endDate: end, preset: preset));

  /// Replaces the range. [preset] is the quick-select that chose these dates,
  /// or null for a calendar pick / an external sync that matches no preset.
  void setRange(DateTime? start, DateTime? end, {BillingQuickRange? preset}) {
    emit(DateRangeState(startDate: start, endDate: end, preset: preset));
  }

  /// Applies a quick-select preset for the current school day.
  void applyPreset(BillingQuickRange preset) {
    final b = preset.bounds;
    setRange(b.start, b.end, preset: preset);
  }

  /// Syncs dates pushed in by the owning screen. The current preset survives
  /// only if the new dates are still exactly its period.
  void syncExternal(DateTime? start, DateTime? end) {
    if (start == state.startDate && end == state.endDate) return;
    final keep = state.preset;
    setRange(
      start,
      end,
      preset: keep != null && keep.matches(start, end) ? keep : null,
    );
  }
}
