import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/date_utils.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/calendar_responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_icon.dart';

class CustomDateTimeField extends StatefulWidget {
  const CustomDateTimeField({
    this.label,
    this.hasLabel = true,
    this.labelStyle,
    this.isTime = false,
    this.isRangePicker = false,
    this.onDateSelected,
    this.onTimeSelected,
    this.initialDate,
    this.initialTime,
    this.onRangeSelected,
    this.fetchInitialTime = true, // New property to control fetch behavior
    this.isDisabled = false,
    this.isRequired = false, // ✅ ADD THIS
    this.firstDate,
    this.lastDate,
    this.dateFormat, // Optional custom date format string
    this.errorText,
    this.onClear,
    this.minuteInterval,
    super.key,
  });

  final String? label;
  final bool hasLabel;
  final TextStyle? labelStyle;
  final bool isRequired;
  final bool isTime;
  final bool isRangePicker;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<TimeOfDay>? onTimeSelected;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final bool fetchInitialTime; // Control whether to fetch current time
  final bool isDisabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  // Add callback for date range selection
  final Function(DateTime, DateTime?)? onRangeSelected;

  final String? dateFormat;

  /// Time mode only: text shown below the well, e.g. a validation message.
  final String? errorText;

  /// Time mode only: shows a small close (x) next to the clock icon when a
  /// time is already picked, letting the user clear it.
  final VoidCallback? onClear;

  /// Time mode only: restricts the picker to minute multiples of this value
  /// (e.g. 15) with a wheel picker, instead of the normal themed clock dial.
  final int? minuteInterval;

  @override
  State<CustomDateTimeField> createState() => _CustomDateTimeFieldState();
}

class _CustomDateTimeFieldState extends State<CustomDateTimeField> {
  String? selectedValue;
  DateTime? selectedDate;
  DateTime? rangeEndDate;
  TimeOfDay? selectedTime;
  String? hour;
  String? minute;
  String? period;

  @override
  void initState() {
    super.initState();

    // Initialize with provided initialDate if available
    if (widget.initialDate != null) {
      selectedDate = widget.initialDate;
      _updateDisplayValue();
    }

    // Initialize with provided initialTime if available
    if (widget.initialTime != null) {
      selectedTime = widget.initialTime;
      if (widget.isTime) {
        _updateTimeComponents(selectedTime!);
      }
      _updateDisplayValue();
    }

    // Only fetch current date/time if fetchInitialTime is true
    if (widget.fetchInitialTime) {
      setCurrentDateTime().then((_) {
        // If it's a range picker, default to current month's range based on adjusted date
        if (widget.isRangePicker) {
          if (selectedDate != null) {
            // Set to first day of current month from the timezone-adjusted date
            selectedDate = DateTime(selectedDate!.year, selectedDate!.month, 1);

            // Calculate last day of month based on timezone-adjusted date
            final lastDayOfMonth = DateTime(
              selectedDate!.year,
              selectedDate!.month + 1,
              0,
              23,
              59,
              59,
            );
            rangeEndDate = lastDayOfMonth;
          }
        }

        // Update display after timezone adjustment
        _updateDisplayValue();

        // If time component is needed, update time components
        if (widget.isTime && selectedTime != null) {
          _updateTimeComponents(selectedTime!);
        }
      });
    }
  }

  // Modified to return Future so we can await it

  Future<void> setCurrentDateTime() async {
    DateTime dateTime = AppTime.now();
    try {
      // resolveForCurrentSchool pulls a fresh server clock as part of resolving,
      // so schoolCalendarDateAndTimeNow below reflects authoritative "now".
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
            storage: serviceLocator<StorageService>(),
            apiClient: serviceLocator<ApiClient>(),
          );
      final dt = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
        schoolTimeZone,
      );
      dateTime = DateTime(
        dt.$1.year,
        dt.$1.month,
        dt.$1.day,
        dt.$2.hour,
        dt.$2.minute,
      );
    } catch (_) {
      // Fallback to local device time.
    }
    if (!mounted) return;
    setState(() {
      selectedDate = dateTime; // Store the entire dateTime object
      selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    });
  }

  @override
  void didUpdateWidget(covariant CustomDateTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTime && widget.initialTime != oldWidget.initialTime) {
      setState(() {
        selectedTime = widget.initialTime!;
        _updateTimeComponents(selectedTime!);
        _updateDisplayValue();
      });
    }

    if (!widget.isTime &&
        widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate) {
      setState(() {
        selectedDate = widget.initialDate!;
        _updateDisplayValue();
      });
    }
  }

  void _updateTimeComponents(TimeOfDay time) {
    hour = time.hourOfPeriod == 0 ? '12' : time.hourOfPeriod.toString();
    minute = time.minute.toString().padLeft(2, '0');
    period = time.period == DayPeriod.am ? 'AM' : 'PM';
  }

  void _updateDisplayValue() {
    if (widget.isRangePicker) {
      if (selectedDate != null) {
        if (rangeEndDate != null) {
          final startStr = widget.dateFormat != null
              ? DateFormat(widget.dateFormat!).format(selectedDate!)
              : DateUtilsNew.formatToReadableDate(selectedDate!);
          final endStr = widget.dateFormat != null
              ? DateFormat(widget.dateFormat!).format(rangeEndDate!)
              : DateUtilsNew.formatToReadableDate(rangeEndDate!);
          selectedValue = "$startStr - $endStr";
        } else {
          selectedValue = widget.dateFormat != null
              ? DateFormat(widget.dateFormat!).format(selectedDate!)
              : DateUtilsNew.formatToReadableDate(selectedDate!);
        }
      }
    } else if (widget.isTime) {
      if (selectedTime != null) {
        final hourDisplay = selectedTime!.hourOfPeriod == 0
            ? '12'
            : selectedTime!.hourOfPeriod.toString();
        selectedValue =
            "$hourDisplay:${selectedTime!.minute.toString().padLeft(2, '0')} ${selectedTime!.period == DayPeriod.am ? 'AM' : 'PM'}";
      }
    } else {
      if (selectedDate != null) {
        selectedValue = widget.dateFormat != null
            ? DateFormat(widget.dateFormat!).format(selectedDate!)
            : DateUtilsNew.formatToReadableDate(selectedDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTime) {
      return _buildTimeField(context);
    }
    final calHelper = CalendarResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hasLabel && widget.label != null)
          RichText(
            text: TextSpan(
              text: widget.label!,
              style:
                  widget.labelStyle ??
                  TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                    fontSize: calHelper.headerFontSize * 0.7,
                    fontWeight: FontWeight.w400,
                  ),
              children: [
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: MaterialHues.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        if (widget.hasLabel && widget.label != null)
          SizedBox(height: calHelper.calendarPadding * 0.75),
        GestureDetector(
          onTap: () async {
            if (widget.isDisabled == true) {
              return; // Prevent interaction if disabled
            }
            final result = await showDialog(
              context: context,
              builder: (_) => CalendarDialog(
                isRangePicker: widget.isRangePicker,
                isTimePicker: widget.isTime,
                initialDate: selectedDate,
                initialTime: selectedTime,
                initialEndDate: rangeEndDate,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
              ),
            );
            if (result != null) {
              setState(() {
                if (widget.isRangePicker) {
                  // Handle range selection
                  if (result['startDate'] != null &&
                      result['startDate'] is DateTime) {
                    selectedDate = result['startDate'];
                    rangeEndDate = result['endDate'] is DateTime
                        ? result['endDate']
                        : null;
                    widget.onRangeSelected?.call(selectedDate!, rangeEndDate);
                  }
                } else if (widget.isTime) {
                  // Handle time selection
                  final time = result['time'] as TimeOfDay;
                  selectedTime = time;

                  // Update time components and notify parent
                  _updateTimeComponents(time);
                  widget.onTimeSelected?.call(selectedTime!);
                } else {
                  // Handle single date selection
                  if (result['date'] != null && result['date'] is DateTime) {
                    selectedDate = result['date'];
                    widget.onDateSelected?.call(selectedDate!);
                  }
                }

                // Update the display value
                _updateDisplayValue();
              });
            }
          },
          child: Container(
            constraints: BoxConstraints(minHeight: calHelper.dayCellSize * 1.2),
            padding: EdgeInsets.symmetric(
              horizontal: calHelper.calendarPadding,
            ),
            decoration: widget.isDisabled == true
                ? AppSurfaces.well(radius: 10, color: AppPalette.surfaceMuted)
                : AppSurfaces.well(radius: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedValue ??
                        (widget.isTime
                            ? 'Select Time'
                            : widget.isRangePicker
                            ? 'Select Date Range'
                            : 'Select Date'),
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: calHelper.dayFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppIcon(
                  widget.isTime ? MediaRes.clock_icon : MediaRes.calender_icon,
                  width: calHelper.dayCellSize * 0.7,
                  height: calHelper.dayCellSize * 0.7,
                  color: AppColors.primaryColor.withValues( alpha: widget.isDisabled == true ? 0.5 : 1.0, ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Getter methods to access selected date and time
  DateTime? get date => selectedDate;
  DateTime? get endDate => rangeEndDate;
  TimeOfDay? get time => selectedTime;
  String get getHour => hour ?? '';
  String get getMinute => minute ?? '';
  String get getPeriod => period ?? '';

  // ═══════════════════════════════════════════════════════════════════════
  // Time mode: a plain time-of-day picker, no calendar grid attached.
  // ═══════════════════════════════════════════════════════════════════════

  String _formatHourMinute(TimeOfDay? t) {
    if (t == null) return 'hh:mm AM';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTimeOfDay(BuildContext context) async {
    if (widget.minuteInterval != null) {
      return _pickTimeOfDayRestricted(context);
    }

    final initial = widget.initialTime ?? const TimeOfDay(hour: 9, minute: 0);

    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              timePickerTheme: TimePickerThemeData(
                dialHandColor: AppColors.themeColor,
                hourMinuteTextColor: AppColors.primaryColor,
                hourMinuteColor: AppColors.themeColor.withValues(alpha: 0.15),
                dayPeriodColor: AppColors.themeColor.withValues(alpha: 0.15),
                dayPeriodTextColor: AppColors.primaryColor,
                dayPeriodBorderSide: const BorderSide(
                  color: AppColors.themeColor,
                ),
                dialBackgroundColor: AppColors.fieldBackgroundColor,
                backgroundColor: AppColors.cardColor,
                entryModeIconColor: AppColors.themeColor,
              ),
              colorScheme: theme.colorScheme.copyWith(
                primary: AppPalette.brand,
                secondary: AppPalette.brand,
                onPrimary: AppPalette.onBrand,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        widget.onTimeSelected?.call(picked);
      }
    } catch (_) {}
  }

  Future<void> _pickTimeOfDayRestricted(BuildContext context) async {
    final interval = widget.minuteInterval!;
    final now = widget.initialTime ?? const TimeOfDay(hour: 9, minute: 0);
    final snappedMinute = (now.minute ~/ interval) * interval;
    var selected = DateTime(2020, 1, 1, now.hour, snappedMinute);

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const Text(
                        'Select time',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(
                          TimeOfDay(hour: selected.hour, minute: selected.minute),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontWeight: FontWeight.w700,
                            color: AppColors.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    minuteInterval: interval,
                    use24hFormat: false,
                    initialDateTime: selected,
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) widget.onTimeSelected?.call(result);
  }

  Widget _buildTimeField(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final hasLabel = widget.label != null && widget.label!.isNotEmpty;
    final enabled = !widget.isDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          RichText(
            text: TextSpan(
              text: widget.label,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
              children: [
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: MaterialHues.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: enabled ? () => _pickTimeOfDay(context) : null,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Container(
              constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
              decoration: AppSurfaces.well(
                radius: responsive.isTablet ? 12.0 : 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatHourMinute(widget.initialTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onClear != null &&
                      widget.initialTime != null &&
                      enabled) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onClear,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Icon(
                          Icons.close,
                          size: responsive.isTablet ? 20.0 : 18.0,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AppIcon(
                    MediaRes.clock_icon,
                    height: responsive.isTablet ? 20.0 : 18.0,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: MaterialHues.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.body,
            ),
          ),
        ],
      ],
    );
  }
}
