import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/date_range_cubit.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

class AccountingDateRangeSelector extends StatefulWidget {
  const AccountingDateRangeSelector({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.onRangeChanged,
  });

  /// When non-null, initializes / syncs the visible range (e.g. persisted filters).
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  /// Fires after the user applies a range from the calendar dialog.
  final void Function(DateTime? start, DateTime? end)? onRangeChanged;

  @override
  State<AccountingDateRangeSelector> createState() =>
      _AccountingDateRangeSelectorState();
}

class _AccountingDateRangeSelectorState
    extends State<AccountingDateRangeSelector> {
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
      _cubit.setRange(widget.initialStartDate, widget.initialEndDate);
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
      _cubit.setRange(
        result['startDate'] as DateTime?,
        result['endDate'] as DateTime?,
      );
      widget.onRangeChanged?.call(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DateRangeCubit>.value(
      value: _cubit,
      child: BlocBuilder<DateRangeCubit, DateRangeState>(
        builder: (context, _) {
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
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        BillingStrings.selectDateRange,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: _openPicker,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.billingBorderLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                          SvgPicture.asset(
                            MediaRes.calender_icon,
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
