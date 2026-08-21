import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/calendar_responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class ReportFormLayout extends StatelessWidget {
  const ReportFormLayout({
    super.key,
    required this.title,
    required this.child,
    required this.onGenerate,
    this.isLoading = false,
    this.generateLabel = 'Generate Report',
    this.showButton = true,
  });

  final String title;
  final Widget child;
  final VoidCallback? onGenerate;
  final bool isLoading;
  final String generateLabel;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: responsive.containerWidth,
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing,
                    ),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [child],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: !showButton
          ? null
          : Container(
              padding: EdgeInsets.only(
                bottom: safeAreaBottom,
                left: 16,
                right: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                  topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                ),
              ),
              child: CustomButtonLayout(
                confirmButtonLabel: generateLabel,
                onPressedConfirm: onGenerate,
                showCancelButton: false,
                isForm: false,
                isLoading: isLoading,
              ),
            ),
    );
  }
}

/// Reusable required-asterisk label used in report forms.
class ReportFieldLabel extends StatelessWidget {
  const ReportFieldLabel({
    super.key,
    required this.label,
    this.isRequired = true,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.isTablet ? 8.0 : 6.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            color: const Color(0xff573353),
          ),
          children: [
            TextSpan(text: label),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.red),
              ),
          ],
        ),
      ),
    );
  }
}

/// Month + year picker styled to match [CustomDateTimeField]: same light field
/// background, padding, calendar icon, and selected-text style. Opens a
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
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMonth;
  }

  @override
  void didUpdateWidget(covariant ReportMonthYearField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth &&
        widget.initialMonth != null) {
      _selected = widget.initialMonth;
    }
  }

  Future<void> _openPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthYearPickerDialog(
        initialMonth: _selected ?? AppTime.now(),
        firstYear: widget.firstYear,
        lastYear: widget.lastYear,
      ),
    );
    if (picked != null) {
      setState(() => _selected = picked);
      widget.onMonthSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calHelper = CalendarResponsiveHelper(context);
    final display = _selected != null
        ? DateFormat('MMM, yyyy').format(_selected!)
        : 'Select Month';

    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        constraints: BoxConstraints(minHeight: calHelper.dayCellSize * 1.2),
        padding: EdgeInsets.symmetric(horizontal: calHelper.calendarPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.fieldbackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: calHelper.dayFontSize,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SvgPicture.asset(
              MediaRes.calender_icon,
              width: calHelper.dayCellSize * 0.7,
              height: calHelper.dayCellSize * 0.7,
              colorFilter: ColorFilter.mode(
                AppColors.primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
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
    'Dec',
  ];

  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  int get _minYear => widget.firstYear ?? (AppTime.now().year - 10);
  int get _maxYear => widget.lastYear ?? (AppTime.now().year + 10);

  void _select(int monthIndex) {
    Navigator.of(context).pop(DateTime(_year, monthIndex + 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = widget.initialMonth.month - 1;
    final selectedYear = widget.initialMonth.year;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xff573353),
                  ),
                  onPressed: _year > _minYear
                      ? () => setState(() => _year--)
                      : null,
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff573353),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xff573353),
                  ),
                  onPressed: _year < _maxYear
                      ? () => setState(() => _year++)
                      : null,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
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
                    _year == selectedYear && index == selectedMonth;
                return InkWell(
                  onTap: () => _select(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffEEEDF0)
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _monthNames[index],
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// "Note: All Classrooms will be selected by Default." style helper text.
class ReportDefaultNote extends StatelessWidget {
  const ReportDefaultNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xff4F46E5),
        ),
      ),
    );
  }
}

/// Report format selector dropdown (PDF/XLSX)
class ReportFormatSelector extends StatelessWidget {
  const ReportFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
    this.showLabel = true,
  });

  final String selectedFormat;
  final ValueChanged<String> onFormatChanged;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return DropdownButtonFormField<String>(
      initialValue: selectedFormat,
      decoration: InputDecoration(
        labelText: showLabel ? 'Export Format *' : null,
        filled: true,
        fillColor: AppColors.fieldbackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(
          fontSize: responsive.labelFontSize,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w400,
          color: const Color(0xff573353),
        ),
        hintText: !showLabel ? 'Select Format' : null,
        hintStyle: TextStyle(
          fontSize: responsive.labelFontSize,
          fontFamily: 'Manrope',
          color: const Color(0xff573353).withValues(alpha: 0.5),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'PDF', child: Text('PDF')),
        DropdownMenuItem(value: 'XLSX', child: Text('XLSX')),
      ],
      onChanged: (value) {
        if (value != null) {
          onFormatChanged(value);
        }
      },
    );
  }
}
