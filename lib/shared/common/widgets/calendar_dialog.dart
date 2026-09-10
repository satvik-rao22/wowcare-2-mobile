import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/shared/common/widgets/calendar_responsive_helper.dart';
import 'package:intl/intl.dart';

class CalendarDialog extends StatefulWidget {
  final bool isRangePicker;
  final bool isTimePicker;
  final DateTime? initialDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialTime;
  final bool whiteBgColor;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CalendarDialog({
    Key? key,
    this.isRangePicker = false,
    this.isTimePicker = true,
    this.initialDate,
    this.initialEndDate,
    this.initialTime,
    this.whiteBgColor = false,
    this.firstDate,
    this.lastDate,
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

  /// "Today" in the school's timezone — drives the calendar's current-day ring
  /// and the default start date, so the picker opens on the school's calendar
  /// day (e.g. IST) rather than the device's.
  late DateTime _schoolToday;

  @override
  void initState() {
    super.initState();
    // Default "now"/"today" to the SCHOOL timezone, not the device. Use the
    // last-known zone synchronously for the first frame, then refine from the
    // resolver. An explicit initialDate/initialTime is always respected.
    final nowParts = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
      SchoolTimezoneResolver.lastKnownTimeZone,
    );
    _schoolToday = nowParts.$1;
    _selectedDate = widget.initialDate;
    _rangeStartDate = widget.initialDate ?? nowParts.$1;
    _rangeEndDate = widget.initialEndDate;
    _selectedTime = widget.initialTime ?? nowParts.$2;

    _hourController = TextEditingController(
      text: _selectedTime.hourOfPeriod == 0
          ? '12'
          : _selectedTime.hourOfPeriod.toString(),
    );
    _minuteController = TextEditingController(
      text: _selectedTime.minute.toString().padLeft(2, '0'),
    );

    _refreshSchoolNow();
  }

  /// Resolves the current school's timezone (cache/API) and updates the
  /// school-today marker + any defaults the caller didn't pin.
  Future<void> _refreshSchoolNow() async {
    try {
      // resolveForCurrentSchool refreshes the server clock as part of resolving,
      // so "today"/"now" defaults below are authoritative at open time.
      final tzName = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: serviceLocator<StorageService>(),
        apiClient: serviceLocator<ApiClient>(),
      );
      if (!mounted) return;
      final parts = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(tzName);
      setState(() {
        _schoolToday = parts.$1;
        if (widget.initialDate == null) _rangeStartDate = parts.$1;
        if (widget.initialTime == null) {
          _selectedTime = parts.$2;
          _hourController.text = parts.$2.hourOfPeriod == 0
              ? '12'
              : parts.$2.hourOfPeriod.toString();
          _minuteController.text = parts.$2.minute.toString().padLeft(2, '0');
        }
      });
    } catch (_) {
      // Keep the last-known-zone defaults.
    }
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
          : DateFormat('MMM dd, yyyy').format(_selectedDate!);
    }
    if (_rangeEndDate == null) {
      return DateFormat('MMM dd, yyyy').format(_rangeStartDate!);
    }
    return '${DateFormat('MMM dd, yyyy').format(_rangeStartDate!)} -\n'
        '${DateFormat('MMM dd, yyyy').format(_rangeEndDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final calHelper = CalendarResponsiveHelper(context);
    final double dialogWidth = calHelper.isLargeTablet
        ? 600
        : (calHelper.isTablet ? 400 : calHelper.calendarWidth);
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.95;

    final double controlsFontSize = calHelper.isLargeTablet
        ? 18
        : (calHelper.isTablet ? 16 : 14);
    final double dayFontSize = calHelper.isLargeTablet
        ? 16
        : (calHelper.isTablet ? 15 : 13);
    final double yearFontSize = calHelper.isLargeTablet
        ? 18
        : (calHelper.isTablet ? 16 : 14);
    final double controlsHeight = calHelper.isTablet ? 50 : 44;
    final double hourMinuteFieldWidth = calHelper.isTablet ? 56 : 46;
    final double amPmMinWidth = calHelper.isTablet ? 80 : 64;

    return Dialog(
      backgroundColor: widget.whiteBgColor ? AppPalette.surfaceCard : null,
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
                  const Divider(height: 2, color: MaterialHues.grey300),
                  SizedBox(height: calHelper.calendarPadding * 0.4),
                  SizedBox(
                    height: calHelper.isTablet ? 320 : 280,
                    width: double.infinity,
                    child: CalendarDatePicker2(
                      config: CalendarDatePicker2Config(
                        calendarType: widget.isRangePicker
                            ? CalendarDatePicker2Type.range
                            : CalendarDatePicker2Type.single,
                        selectedDayHighlightColor: AppPalette.brand,
                        centerAlignModePicker: true,
                        firstDate: widget.firstDate ?? DateTime(2000),
                        lastDate: widget.lastDate ?? DateTime(2100),
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
                          color: AppPalette.onBrand,
                        ),
                        yearTextStyle: TextStyle(
                          fontSize: yearFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        // School-timezone "today" so the current-day ring isn't
                        // the device's day when they differ (e.g. IST vs UTC).
                        currentDate: _schoolToday,
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
                              _rangeEndDate = dates.length > 1
                                  ? dates[1]
                                  : null;
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
                                  color: AppPalette.border,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                child: SizedBox(
                                  width: hourMinuteFieldWidth,
                                  child: TextField(
                                    controller: _hourController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^[0-9]*$'),
                                      ),
                                      LengthLimitingTextInputFormatter(2),
                                      TextInputFormatter.withFunction((
                                        oldValue,
                                        newValue,
                                      ) {
                                        if (newValue.text.isEmpty) {
                                          return newValue;
                                        }
                                        final value = int.tryParse(
                                          newValue.text,
                                        );
                                        if (value == null) return oldValue;
                                        if (value < 1) {
                                          return const TextEditingValue(
                                            text: '1',
                                          );
                                        }
                                        if (value > 12) {
                                          return const TextEditingValue(
                                            text: '12',
                                          );
                                        }
                                        return newValue;
                                      }),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'HH',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: calHelper.isTablet ? 20 : 18,
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
                                            hour:
                                                hour % 12 +
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
                              AppIcon(MediaRes.saperator, tone: IconTone.muted),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppPalette.border,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                child: SizedBox(
                                  width: hourMinuteFieldWidth,
                                  child: TextField(
                                    controller: _minuteController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^[0-9]*$'),
                                      ),
                                      LengthLimitingTextInputFormatter(2),
                                      TextInputFormatter.withFunction((
                                        oldValue,
                                        newValue,
                                      ) {
                                        if (newValue.text.isEmpty) {
                                          return newValue;
                                        }
                                        final value = int.tryParse(
                                          newValue.text,
                                        );
                                        if (value == null) return oldValue;
                                        if (value > 59) {
                                          return const TextEditingValue(
                                            text: '59',
                                          );
                                        }
                                        return newValue;
                                      }),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'MM',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: calHelper.isTablet ? 20 : 18,
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
                                        hour:
                                            _selectedTime.hour % 12 +
                                            (index == 1 ? 12 : 0),
                                        minute: _selectedTime.minute,
                                      );
                                    });
                                  },
                                  children: const [
                                    Text(
                                      'AM',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'PM',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                              side: const BorderSide(color: AppPalette.brand),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.brand,
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
                          decoration: AppSurfaces.key(
                            KeyVariant.primary,
                            radius: 8,
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
                                fontFamily: AppFonts.body,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.onBrand,
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
