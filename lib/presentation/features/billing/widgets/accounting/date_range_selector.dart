import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/model/billing_quick_range.dart';
import 'package:wowcare/presentation/features/billing/view_model/date_range_cubit.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';
import 'package:wowcare/core/theme/app_icon.dart';

/// Date-range filter card shared by the Student(s) and Transactions billing
/// tabs: a calendar range field, a "Select Range" quick-pick dropdown
/// (This year / This month / This week) and a Clear All chip.
///
/// Picking a quick range writes its period into the calendar field; picking
/// from the calendar clears the quick-range selection. Clear All hands back to
/// the owner via [onClear], which restores the tab's page-load default.
///
/// The calendar field and the dropdown sit side by side when the card is at
/// least [_sideBySideMinWidth] wide (tablets) and stack on phones, where a
/// shared row truncated the range's end year.
class AccountingDateRangeSelector extends StatefulWidget {
  const AccountingDateRangeSelector({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.onRangeChanged,
    this.onClear,
  });

  /// When non-null, initializes / syncs the visible range (e.g. persisted filters).
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  /// Fires after the user applies a range from the calendar dialog or picks a
  /// quick range from the dropdown.
  final void Function(DateTime? start, DateTime? end)? onRangeChanged;

  /// Fires when the user taps Clear All. The owner resets to its default
  /// range; the new dates arrive back through [initialStartDate] /
  /// [initialEndDate]. Hidden when null.
  final VoidCallback? onClear;

  @override
  State<AccountingDateRangeSelector> createState() =>
      _AccountingDateRangeSelectorState();
}

class _AccountingDateRangeSelectorState
    extends State<AccountingDateRangeSelector> {
  /// Inner card width below which the field and dropdown stack. A full
  /// "Mon d, yyyy - Mon d, yyyy" label plus the dropdown needs about this
  /// much; a 448dp phone offers ~400.
  static const double _sideBySideMinWidth = 440;

  late final DateRangeCubit _cubit = DateRangeCubit(
    start: widget.initialStartDate,
    end: widget.initialEndDate,
  );
  DateTime? get _startDate => _cubit.state.startDate;
  DateTime? get _endDate => _cubit.state.endDate;

  @override
  void didUpdateWidget(covariant AccountingDateRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStartDate != oldWidget.initialStartDate ||
        widget.initialEndDate != oldWidget.initialEndDate) {
      _cubit.syncExternal(widget.initialStartDate, widget.initialEndDate);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatShort(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _currentLabel() {
    if (_startDate != null && _endDate != null) {
      return '${_formatShort(_startDate!)} - ${_formatShort(_endDate!)}';
    }
    return BillingStrings.selectDateRange;
  }

  Future<void> _openPicker() async {
    // Default window anchored to the SCHOOL calendar, so "last 7 days" means the
    // school's last 7 days regardless of the device's zone.
    final DateTime today = billingSchoolToday();
    final DateTime start =
        _startDate ?? today.subtract(const Duration(days: 7));
    final DateTime end = _endDate ?? today;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CalendarDialog(
        isRangePicker: true,
        isTimePicker: false,
        initialDate: start,
        initialEndDate: end.isAfter(start) ? end : start,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      // A calendar pick is a custom range: the quick-range selection resets.
      _cubit.setRange(
        result['startDate'] as DateTime?,
        result['endDate'] as DateTime?,
      );
      widget.onRangeChanged?.call(_startDate, _endDate);
    }
  }

  void _onQuickRangeSelected(String? label) {
    final preset = BillingQuickRange.fromLabel(label);
    if (preset == null) return;
    _cubit.applyPreset(preset);
    widget.onRangeChanged?.call(_startDate, _endDate);
  }

  void _onClear() {
    // Drop the preset right away so the dropdown resets even if the owner's
    // default happens to equal the dates already shown.
    _cubit.setRange(_startDate, _endDate);
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DateRangeCubit>.value(
      value: _cubit,
      child: BlocBuilder<DateRangeCubit, DateRangeState>(
        builder: (context, state) {
          return Card(
            elevation: 0,
            color: AppColors.billingCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          BillingStrings.selectDateRange,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onClear != null) ...[
                        const SizedBox(width: 8),
                        CustomClearAllChip(onTap: _onClear),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final field = _calendarField();
                      final dropdown = _quickRangeDropdown(state);
                      if (constraints.maxWidth >= _sideBySideMinWidth) {
                        return Row(
                          children: [
                            Expanded(flex: 3, child: field),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: dropdown),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [field, const SizedBox(height: 8), dropdown],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _calendarField() {
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        height: 40,
        decoration: AppSurfaces.well(radius: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _currentLabel(),
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.billingTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppIcon(MediaRes.calender_icon, width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _quickRangeDropdown(DateRangeState state) {
    return CustomDropdown(
      hintText: BillingStrings.selectRange,
      items: BillingQuickRange.labels,
      selectedItem: state.preset?.label,
      fieldHeight: 40,
      showAsterisk: false,
      onSelect: _onQuickRangeSelected,
    );
  }
}
