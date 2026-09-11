import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class DateWidget extends StatefulWidget {
  const DateWidget({
    super.key,
    this.isEditable = true,
    this.isRequired = false,
    this.initialDate,
    this.onDateChanged,
  });
  final bool isEditable;
  final bool isRequired;
  final String? initialDate;
  final ValueChanged<DateTime?>? onDateChanged;

  @override
  State<DateWidget> createState() => _DateWidgetState();
}

class _DateWidgetState extends State<DateWidget> {
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final hasInitial =
        widget.initialDate != null && widget.initialDate!.trim().isNotEmpty;
    if (hasInitial) {
      try {
        _selectedDate = DateFormat(
          'dd MMM yyyy',
        ).parseLoose(widget.initialDate!.trim());
      } catch (e) {
        try {
          _selectedDate = DateFormat(
            'MMM dd, yyyy',
          ).parseLoose(widget.initialDate!.trim());
        } catch (e) {
          _selectedDate = AppTime.now(); // fallback
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateChanged?.call(_selectedDate);
      });
    } else {
      // Prefer school calendar from last resolved tz (warm after Activities tab);
      // avoid pushing device-local "today" into parent before async resolve.
      final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
      if (tz.isNotEmpty &&
          tz.toUpperCase() !=
              SchoolTimezoneResolver.fallbackTimeZone.toUpperCase()) {
        _selectedDate = SchoolZoneDateTime.schoolCalendarTodayOnly(tz);
      } else {
        _selectedDate = AppTime.now();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateChanged?.call(_selectedDate);
      });
    }
    _setSchoolDefaultDateIfNeeded();
  }

  Future<void> _setSchoolDefaultDateIfNeeded() async {
    if (widget.initialDate != null && widget.initialDate!.trim().isNotEmpty)
      return;
    final schoolTimeZone = await context
        .read<ActivityEditorCubit>()
        .resolveSchoolTimezone();
    final schoolToday = SchoolZoneDateTime.schoolCalendarTodayOnly(
      schoolTimeZone,
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = schoolToday;
    });
    widget.onDateChanged?.call(_selectedDate);
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
            style: AppTextStyles.activityFieldLabel,
            children: [
              TextSpan(text: 'Date'),
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: AppTextStyles.activityRequiredMarker,
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Opacity(
          opacity: opacity,
          child: _datePickerFilter(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
              widget.onDateChanged?.call(_selectedDate);
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
      onTap: widget.isEditable
          ? () async {
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
            }
          : null,
      child: Container(
        height: 48,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: AppColors.activitySoftPurpleFieldColor.withValues(
            alpha: 0.102,
          ),
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
                  style: AppTextStyles.activityDateValueText(
                    hasValue: selectedDate != null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
