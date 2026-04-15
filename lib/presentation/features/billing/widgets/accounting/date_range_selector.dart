import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/svg.dart';

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
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void didUpdateWidget(covariant AccountingDateRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStartDate != oldWidget.initialStartDate ||
        widget.initialEndDate != oldWidget.initialEndDate) {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
    }
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
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _currentLabel() {
    if (_startDate != null && _endDate != null) {
      return '${_formatShort(_startDate!)} - ${_formatShort(_endDate!)}';
    }
    return 'Select Date Range';
  }

  Future<void> _openPicker() async {
    final DateTime start =
        _startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final DateTime end = _endDate ?? DateTime.now();
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
      setState(() {
        _startDate = result['startDate'] as DateTime?;
        _endDate = result['endDate'] as DateTime?;
      });
      widget.onRangeChanged?.call(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withOpacity(0.1),
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
                  'Select Date Range',
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
                  color: const Color(0x1AB1AFE9),
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
                          fontFamily: 'Manrope',
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
  }
}


