import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/calendar_dialog.dart';
import '../../../../shared/utils/responsive_helper.dart';

class DateWidget extends StatefulWidget {
  const DateWidget({super.key, this.isEditable = true, this.isRequired = false, this.initialDate});
  final bool isEditable;
  final bool isRequired;
  final String? initialDate;

  @override
  State<DateWidget> createState() => _DateWidgetState();
}

class _DateWidgetState extends State<DateWidget> {
  //DateTime? _selectedDate = DateTime.now();
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null && widget.initialDate!.trim().isNotEmpty) {
      try {
        _selectedDate = DateFormat('dd MMM yyyy').parseLoose(widget.initialDate!.trim());
      } catch (e) {
        try {
          _selectedDate = DateFormat('MMM dd, yyyy').parseLoose(widget.initialDate!.trim());
        } catch (e) {
          _selectedDate = DateTime.now(); // fallback
        }
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }


  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double opacity = widget.isEditable ? 1.0 : 0.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize:  13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Manrope',
            ),
            children: [
              TextSpan(text: 'Date'),
              if (widget.isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),
        Opacity(
          opacity: opacity,
          child: _datePickerFilter(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _datePickerFilter({
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return GestureDetector(
      onTap: widget.isEditable ? () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => CalendarDialog(
            isTimePicker: false,
            initialDate: selectedDate,
            whiteBgColor: true,
          ),
        );

        if (result != null && result['date'] != null) {
          onDateSelected(result['date'] as DateTime);
        }
      } : null,
      child: Container(
        height: 48,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
            color: const Color(0xFFB1AFE9).withOpacity(0.102),
            //color: const Color(0xFFF8F7FA),
            borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(selectedDate)
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedDate == null
                        ? AppColors.primaryColor.withOpacity(0.6)
                        : AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              //const SizedBox(width: 4),
              SvgPicture.asset(
                MediaRes.calender_icon,
                height: 28.0,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
