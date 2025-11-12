import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/calendar_responsive_helper.dart';

class CalendarDialog extends StatefulWidget {
  final bool isRangePicker;
  final bool isTimePicker;
  final DateTime? initialDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialTime;

  const CalendarDialog({
    Key? key,
    this.isRangePicker = false,
    this.isTimePicker = true,
    this.initialDate,
    this.initialEndDate,
    this.initialTime,
  }) : super(key: key);

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late DateTime? _selectedDate;
  late DateTime? _rangeStartDate;
  late DateTime? _rangeEndDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _rangeStartDate = widget.initialDate ?? DateTime.now();
    _rangeEndDate = widget.initialEndDate;
    _selectedTime = widget.initialTime ?? TimeOfDay.now();

    _hourController = TextEditingController(
      text: _selectedTime.hourOfPeriod == 0
          ? '12'
          : _selectedTime.hourOfPeriod.toString(),
    );
    _minuteController = TextEditingController(
      text: _selectedTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    final focus = FocusScope.of(context);
    if (!focus.hasPrimaryFocus && focus.focusedChild != null) {
      focus.unfocus();
    } else {
      focus.unfocus();
    }
  }

  String _headerText() {
    if (!widget.isRangePicker) {
      return _selectedDate == null
          ? 'Select Date'
          : DateUtilsNew.formatToShortReadableDate(_selectedDate!);
    }
    if (_rangeEndDate == null) {
      return DateUtilsNew.formatToShortReadableDate(_rangeStartDate!);
    }
    return '${DateUtilsNew.formatToShortReadableDate(_rangeStartDate!)} -\n'
        '${DateUtilsNew.formatToShortReadableDate(_rangeEndDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final calHelper = CalendarResponsiveHelper(context);
    final double dialogWidth = calHelper.isLargeTablet
        ? 600
        : (calHelper.isTablet ? 400 : calHelper.calendarWidth);
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.95;

    final double controlsFontSize =
        calHelper.isLargeTablet ? 18 : (calHelper.isTablet ? 16 : 14);
    final double dayFontSize =
        calHelper.isLargeTablet ? 16 : (calHelper.isTablet ? 15 : 13);
    final double yearFontSize =
        calHelper.isLargeTablet ? 18 : (calHelper.isTablet ? 16 : 14);
    final double controlsHeight = calHelper.isTablet ? 50 : 44;
    final double hourMinuteFieldWidth = calHelper.isTablet ? 56 : 46;
    final double amPmMinWidth = calHelper.isTablet ? 80 : 64;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        vertical: calHelper.calendarMargin * 0.5,
        horizontal: calHelper.calendarMargin,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismissKeyboard,
          onPanDown: (_) => _dismissKeyboard(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: calHelper.calendarPadding,
              horizontal: calHelper.calendarPadding * 0.75,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.isRangePicker
                            ? 'Select date range'
                            : (widget.isTimePicker
                                ? 'Select date & time'
                                : 'Select date'),
                        style: TextStyle(
                          fontSize: calHelper.headerFontSize * 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: calHelper.calendarPadding * 0.5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _headerText(),
                          style: TextStyle(
                            fontSize: calHelper.headerFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: calHelper.calendarPadding * 0.4),
                  const Divider(
                    height: 2,
                    color: Color(0xFFE0E0E0),
                  ),
                  SizedBox(height: calHelper.calendarPadding * 0.4),
                  SizedBox(
                    height: calHelper.isTablet ? 320 : 280,
                    width: double.infinity,
                    child: CalendarDatePicker2(
                      config: CalendarDatePicker2Config(
                        calendarType: widget.isRangePicker
                            ? CalendarDatePicker2Type.range
                            : CalendarDatePicker2Type.single,
                        selectedDayHighlightColor:
                            AppColors.primaryGradientColors.first,
                        centerAlignModePicker: true,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        controlsHeight: controlsHeight,
                        controlsTextStyle: TextStyle(
                          fontSize: controlsFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        dayTextStyle: TextStyle(
                          fontSize: dayFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        selectedDayTextStyle: TextStyle(
                          fontSize: dayFontSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                        yearTextStyle: TextStyle(
                          fontSize: yearFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        currentDate: widget.isRangePicker ? null : null,
                      ),
                      value: widget.isRangePicker
                          ? (_rangeEndDate != null
                              ? [_rangeStartDate, _rangeEndDate]
                              : [_rangeStartDate])
                          : (_selectedDate == null ? [] : [_selectedDate!]),
                      onValueChanged: (dates) {
                        setState(() {
                          if (dates.isNotEmpty) {
                            if (widget.isRangePicker) {
                              _rangeStartDate = dates.first;
                              _rangeEndDate =
                                  dates.length > 1 ? dates[1] : null;
                            } else {
                              _selectedDate = dates.first;
                            }
                          } else if (!widget.isRangePicker) {
                            _selectedDate = null;
                          }
                        });
                      },
                    ),
                  ),
                  if (!widget.isRangePicker && widget.isTimePicker)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color.fromRGBO(87, 51, 83, 0.1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 0),
                                child: SizedBox(
                                  width: hourMinuteFieldWidth,
                                  child: TextField(
                                    controller: _hourController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^[0-9]*$')),
                                      LengthLimitingTextInputFormatter(2),
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        if (newValue.text.isEmpty) {
                                          return newValue;
                                        }
                                        final value =
                                            int.tryParse(newValue.text);
                                        if (value == null) return oldValue;
                                        if (value < 1) {
                                          return const TextEditingValue(
                                              text: '1');
                                        }
                                        if (value > 12) {
                                          return const TextEditingValue(
                                              text: '12');
                                        }
                                        return newValue;
                                      }),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'HH',
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    style: TextStyle(
                                      fontSize:
                                          calHelper.isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) return;
                                      final hour = int.tryParse(value);
                                      if (hour != null &&
                                          hour >= 1 &&
                                          hour <= 12) {
                                        setState(() {
                                          _selectedTime = TimeOfDay(
                                            hour: hour % 12 +
                                                (_selectedTime.period ==
                                                        DayPeriod.pm
                                                    ? 12
                                                    : 0),
                                            minute: _selectedTime.minute,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Hours',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              const SizedBox(height: 10),
                              SvgPicture.asset(MediaRes.saperator),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color.fromRGBO(87, 51, 83, 0.1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 0),
                                child: SizedBox(
                                  width: hourMinuteFieldWidth,
                                  child: TextField(
                                    controller: _minuteController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^[0-9]*$')),
                                      LengthLimitingTextInputFormatter(2),
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        if (newValue.text.isEmpty) {
                                          return newValue;
                                        }
                                        final value =
                                            int.tryParse(newValue.text);
                                        if (value == null) return oldValue;
                                        if (value > 59) {
                                          return const TextEditingValue(
                                              text: '59');
                                        }
                                        return newValue;
                                      }),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'MM',
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    style: TextStyle(
                                      fontSize:
                                          calHelper.isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) return;
                                      final minute = int.tryParse(value);
                                      if (minute != null &&
                                          minute >= 0 &&
                                          minute <= 59) {
                                        setState(() {
                                          _selectedTime = TimeOfDay(
                                            hour: _selectedTime.hour,
                                            minute: minute,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Minute',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                          Column(
                            children: [
                              SizedBox(
                                width: amPmMinWidth,
                                child: ToggleButtons(
                                  direction: Axis.vertical,
                                  borderRadius: BorderRadius.circular(8),
                                  constraints: BoxConstraints(
                                    minWidth: amPmMinWidth,
                                    minHeight: 40,
                                  ),
                                  isSelected: [
                                    _selectedTime.period == DayPeriod.am,
                                    _selectedTime.period == DayPeriod.pm,
                                  ],
                                  onPressed: (index) {
                                    setState(() {
                                      _selectedTime = TimeOfDay(
                                        hour: _selectedTime.hour % 12 +
                                            (index == 1 ? 12 : 0),
                                        minute: _selectedTime.minute,
                                      );
                                    });
                                  },
                                  children: const [
                                    Text(
                                      'AM',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'PM',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6C7FD8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C7FD8),
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: AppColors.buildPrimaryGradient(),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (widget.isRangePicker) {
                                final DateTime? formattedEndDate =
                                    _rangeEndDate != null
                                        ? DateTime(
                                            _rangeEndDate!.year,
                                            _rangeEndDate!.month,
                                            _rangeEndDate!.day,
                                            23,
                                            59,
                                            59,
                                          )
                                        : null;
                                Navigator.pop(context, {
                                  'startDate': _rangeStartDate,
                                  'endDate': formattedEndDate,
                                });
                              } else {
                                Navigator.pop(context, {
                                  'date': _selectedDate,
                                  'time': _selectedTime,
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




