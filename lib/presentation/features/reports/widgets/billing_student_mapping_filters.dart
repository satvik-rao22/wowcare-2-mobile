import 'package:flutter/material.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// The filter fields unique to the Students & Billing Mapping report: the
/// Monthly/Custom period switch, its date input, export format and classroom.
///
/// Extracted from `billing_report_form_screen.dart` (§6.7).
class BillingStudentMappingFilters extends StatelessWidget {
  const BillingStudentMappingFilters({
    super.key,
    required this.classrooms,
    required this.periodType,
    required this.periodDate,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.selectedClassrooms,
  });

  final List<String> classrooms;
  final ValueNotifier<String> periodType;
  final ValueNotifier<DateTime> periodDate;
  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<DateTime> endDate;
  final ValueNotifier<String> format;
  final ValueNotifier<List<String>> selectedClassrooms;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: periodType,
          builder: (_, v, __) => CustomDropdown(
            label: ReportsStrings.reportPeriodType,
            hintText: ReportsStrings.select,
            items: const ['Monthly', 'Custom'],
            selectedItem: v,
            showAsterisk: true,
            onSelect: (val) {
              if (val != null) {
                periodType.value = val;
              }
            },
          ),
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
        ValueListenableBuilder<String>(
          valueListenable: periodType,
          builder: (_, v, __) => v == 'Monthly'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ReportFieldLabel(label: ReportsStrings.date),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: periodDate,
                      builder: (_, v, __) => ReportMonthYearField(
                        initialMonth: v,
                        onMonthSelected: (d) => periodDate.value = d,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ReportFieldLabel(label: ReportsStrings.dateRange),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: startDate,
                      builder: (_, v, __) => CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: true,
                        fetchInitialTime: false,
                        initialDate: v,
                        onRangeSelected: (start, end) {
                          if (end != null) {
                            startDate.value = start;
                            endDate.value = end;
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
        const ReportFieldLabel(label: ReportsStrings.exportFormat),
        ValueListenableBuilder<String>(
          valueListenable: format,
          builder: (_, v, __) => ReportFormatSelector(
            selectedFormat: v,
            onFormatChanged: (value) => format.value = value,
            showLabel: false,
          ),
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
        ValueListenableBuilder<List<String>>(
          valueListenable: selectedClassrooms,
          builder: (_, selected, __) => CustomMultiSelectDropdown(
            label: ReportsStrings.classroom,
            hintText: ReportsStrings.allClassrooms,
            items: classrooms,
            selectedItems: selected,
            onChanged: (s) => selectedClassrooms.value = s,
            showSelectAll: true,
          ),
        ),
        const ReportDefaultNote(
          text: ReportsStrings.noteAllClassroomsIncludedByDefault,
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
      ],
    );
  }
}
