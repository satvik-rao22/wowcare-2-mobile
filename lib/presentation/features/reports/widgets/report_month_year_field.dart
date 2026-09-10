import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

/// simple year-nav + 3-column month grid (per the report form designs).
class ReportMonthYearField extends StatefulWidget {
  const ReportMonthYearField({
    super.key,
    this.initialMonth,
    this.firstYear,
    this.lastYear,
    this.onMonthSelected,
  });

  final DateTime? initialMonth;
  final int? firstYear;
  final int? lastYear;
  final ValueChanged<DateTime>? onMonthSelected;

  @override
  State<ReportMonthYearField> createState() => _ReportMonthYearFieldState();
}

class _ReportMonthYearFieldState extends State<ReportMonthYearField> {
  /// §2.2 bucket B — the chosen month is UI micro-state for this field.
  final ValueNotifier<DateTime?> _selected = ValueNotifier<DateTime?>(null);

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selected.value = widget.initialMonth;
  }

  @override
  void didUpdateWidget(covariant ReportMonthYearField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth &&
        widget.initialMonth != null) {
      _selected.value = widget.initialMonth;
    }
  }

  Future<void> _openPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthYearPickerDialog(
        initialMonth: _selected.value ?? AppTime.now(),
        firstYear: widget.firstYear,
        lastYear: widget.lastYear,
      ),
    );
    if (picked != null) {
      _selected.value = picked;
      widget.onMonthSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Was CalendarResponsiveHelper. Its boundaries (tablet >600, large >900)
    // now resolve from AppBreakpoints, so these values are unchanged at every
    // width except exactly 600.0 (it used `>`, AppBreakpoints uses `>=`).
    final double dayCellSize = context.isWide
        ? 52.0
        : (context.isTablet ? 46.0 : 40.0);
    final double dayFontSize = context.isWide
        ? 16.0
        : (context.isTablet ? 15.0 : 14.0);
    final double calendarPadding = context.isTablet ? 24.0 : 16.0;
    return ValueListenableBuilder<DateTime?>(
      valueListenable: _selected,
      builder: (context, selected, _) {
        final display = selected != null
            ? DateFormat('MMM, yyyy').format(selected)
            : ReportsStrings.selectMonth;
        return GestureDetector(
          onTap: _openPicker,
          child: Container(
            constraints: BoxConstraints(minHeight: dayCellSize * 1.2),
            padding: EdgeInsets.symmetric(horizontal: calendarPadding),
            decoration: AppSurfaces.well(radius: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: AppTextStyles.reportsFieldValue(
                      fontSize: dayFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppIcon(
                  MediaRes.calender_icon,
                  width: dayCellSize * 0.7,
                  height: dayCellSize * 0.7,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog({
    required this.initialMonth,
    this.firstYear,
    this.lastYear,
  });

  final DateTime initialMonth;
  final int? firstYear;
  final int? lastYear;

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  static const List<String> _monthNames = <String>[
    ReportsStrings.jan,
    ReportsStrings.feb,
    ReportsStrings.mar,
    ReportsStrings.apr,
    ReportsStrings.may,
    ReportsStrings.jun,
    ReportsStrings.jul,
    ReportsStrings.aug,
    ReportsStrings.sep,
    ReportsStrings.oct,
    ReportsStrings.nov,
    ReportsStrings.dec,
  ];

  /// §2.2 bucket B — the visible year in the picker dialog.
  late final ValueNotifier<int> _year;

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _year = ValueNotifier<int>(widget.initialMonth.year);
  }

  int get _minYear => widget.firstYear ?? (AppTime.now().year - 10);
  int get _maxYear => widget.lastYear ?? (AppTime.now().year + 10);

  void _select(int monthIndex) {
    Navigator.of(context).pop(DateTime(_year.value, monthIndex + 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = widget.initialMonth.month - 1;
    final selectedYear = widget.initialMonth.year;

    return ValueListenableBuilder<int>(
      valueListenable: _year,
      builder: (context, year, _) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: year > _minYear ? () => _year.value-- : null,
                  ),
                  Text(
                    '$year',
                    style: AppTextStyles.reportsHeading(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: year < _maxYear ? () => _year.value++ : null,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSizes.xs),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final isSelected =
                      year == selectedYear && index == selectedMonth;
                  return InkWell(
                    onTap: () => _select(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.reportsMonthPickerSelectedColor
                            : AppColors.transparentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _monthNames[index],
                        style: isSelected
                            ? AppTextStyles.reportsHeading(fontSize: 16)
                            : AppTextStyles.reportsFieldValue(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Note: All Classrooms will be selected by Default." style helper text.
