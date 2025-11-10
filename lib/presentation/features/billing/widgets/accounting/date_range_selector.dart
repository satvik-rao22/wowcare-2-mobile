import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/svg.dart';

class AccountingDateRangeSelector extends StatefulWidget {
  const AccountingDateRangeSelector({super.key});

  @override
  State<AccountingDateRangeSelector> createState() =>
      _AccountingDateRangeSelectorState();
}

class _AccountingDateRangeSelectorState
    extends State<AccountingDateRangeSelector> {
  DateTime? _startDate;
  DateTime? _endDate;

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
                          color: Color(0xff573353),
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


