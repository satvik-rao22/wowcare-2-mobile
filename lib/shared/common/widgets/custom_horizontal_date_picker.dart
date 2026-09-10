import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/calendar_responsive_helper.dart';

class CustomHorizontalDatePicker extends StatefulWidget {
  @override
  _CustomHorizontalDatePickerState createState() => _CustomHorizontalDatePickerState();
}

class _CustomHorizontalDatePickerState extends State<CustomHorizontalDatePicker> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = AppTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _previousWeek() {
    setState(() {
      _focusedDay =
          DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day - 7);
    });
  }

  void _nextWeek() {
    setState(() {
      _focusedDay =
          DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day + 7);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calHelper = CalendarResponsiveHelper(context);
    return Row(
      children: [
        Column(
          children: [
            InkWell(
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.primaryColor,
                size: 28,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(100),
              ),
              onTap: _previousWeek,
            ),
            const SizedBox(height: 12),
          ],
        ),
        Expanded(
          child: Container(
            width: calHelper.calendarWidth,
            height: calHelper.calendarHeight * 0.35, // for week view
            padding: EdgeInsets.all(calHelper.calendarPadding),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerVisible: false,
              availableCalendarFormats: const {
                CalendarFormat.week: 'Week',
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                AppLogger.d('Selected:  ${selectedDay.toString().split(' ')[0]}');
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: calHelper.dayFontSize,
                ),
                defaultTextStyle: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: calHelper.dayFontSize,
                ),
                selectedTextStyle: const TextStyle(color: AppColors.whiteColor),
                todayDecoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient().withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: calHelper.dayFontSize,
                ),
                cellPadding: EdgeInsets.all(calHelper.dayCellSize * 0.05),
                cellMargin: EdgeInsets.all(calHelper.dayCellSize * 0.05),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) =>
                    DateFormat.E(locale).format(date)[0],
                weekdayStyle: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: calHelper.dayFontSize * 0.9,
                ),
                weekendStyle: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: calHelper.dayFontSize * 0.9,
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            InkWell(
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.primaryColor,
                size: 28,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(100),
              ),
              onTap: _nextWeek,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}
