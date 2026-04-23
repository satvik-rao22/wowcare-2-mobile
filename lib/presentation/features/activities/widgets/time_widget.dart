import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/utils/responsive_helper.dart';

class TimeWidget extends StatefulWidget {
  const TimeWidget({
    super.key,
    this.isEditable = true,
    this.initialTime,
    this.prefilledTime,
    this.isRequired = false,
    this.label = 'Time',
    this.doNotShowTime = false,
    this.onTimeChanged,
  });

  final bool isEditable;
  final String? prefilledTime;
  final String label;
  final TimeOfDay? initialTime; // Optional initial time
  final bool isRequired;
  final bool doNotShowTime;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = _parseTimeOfDay(widget.prefilledTime) ?? widget.initialTime ?? TimeOfDay.now();
    _setSchoolDefaultTimeIfNeeded();
    // Notify initial value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTimeChanged?.call(_selectedTime);
    });
  }

  Future<void> _setSchoolDefaultTimeIfNeeded() async {
    if (widget.prefilledTime != null && widget.prefilledTime!.trim().isNotEmpty) return;
    if (widget.initialTime != null) return;
    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    final schoolNow = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(schoolTimeZone).$2;
    if (!mounted) return;
    setState(() {
      _selectedTime = schoolNow;
    });
    widget.onTimeChanged?.call(_selectedTime);
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final cleaned = timeStr.trim().replaceAll(' ', '').toUpperCase();
    final regex = RegExp(r'^(\d{1,2}):?(\d{2})\s*(AM|PM)?$', caseSensitive: false);
    final match = regex.firstMatch(cleaned);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);

      if (period != null) {
        if (hour == 12) hour = period == 'AM' ? 0 : 12;
        else if (period == 'PM') hour += 12;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.themeColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xff573353),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      widget.onTimeChanged?.call(_selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double opacity = widget.isEditable ? 1.0 : 0.4;
    final String formattedTime = _selectedTime.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Manrope',
            ),
            children:  [
              TextSpan(text: widget.label),
              if(widget.isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: widget.isEditable ? () => _selectTime(context) : null,
            child: Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB1AFE9).withOpacity(0.102),
                //color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isEditable
                      ? Colors.transparent
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.doNotShowTime ? '' : formattedTime,
                    style: TextStyle(
                      color: AppColors.primaryColor.withOpacity(
                        _selectedTime == widget.initialTime && widget.initialTime == null
                            ? 0.6
                            : 1.0,
                      ),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  SvgPicture.asset(
                    MediaRes.clock_icon ,
                    height: 28.0,
                    width: 28.0,
                    colorFilter: ColorFilter.mode(
                      AppColors.primaryColor.withOpacity(opacity),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}