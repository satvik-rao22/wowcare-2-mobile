import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/model/report_filter_defaults.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// The filter fields unique to the Invoice billing report: invoice status,
/// classroom, and the classroom-dependent student picker.
///
/// Extracted from `billing_report_form_screen.dart` (§6.7) — one of four
/// report-type branches that made the form's build method 300 lines long.
class BillingInvoiceFilters extends StatelessWidget {
  const BillingInvoiceFilters({
    super.key,
    required this.classrooms,
    required this.selectedInvoiceStatuses,
    required this.selectedClassrooms,
    required this.selectedStudents,
    required this.classroomFilter,
    required this.studentFilter,
  });

  final List<String> classrooms;
  final ValueNotifier<List<String>> selectedInvoiceStatuses;
  final ValueNotifier<List<String>> selectedClassrooms;
  final ValueNotifier<List<String>> selectedStudents;
  final ReportFilterDefault classroomFilter;
  final ReportFilterDefault studentFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add the Optional filters:  Payment method (Card, ACH, Cash)
        ValueListenableBuilder<List<String>>(
          valueListenable: selectedInvoiceStatuses,
          builder: (_, selected, __) => CustomMultiSelectDropdown(
            label: ReportsStrings.invoiceStatus,
            hintText: "Select Status",
            isRequired: true,
            items: const ["Paid", "Unpaid", "Partial"],
            selectedItems: selected,
            onChanged: (s) => selectedInvoiceStatuses.value = s,
            showSelectAll: true,
          ),
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
        ValueListenableBuilder<List<String>>(
          valueListenable: selectedClassrooms,
          builder: (_, selected, __) => CustomMultiSelectDropdown(
            label: ReportsStrings.classroom,
            hintText: ReportsStrings.selectClassroom,
            items: classrooms,
            isRequired: true,
            selectedItems: selected,
            onChanged: (s) {
              selectedClassrooms.value = classroomFilter.userSelected(s);
              context.read<ReportsCubit>().loadFormStudents(
                classroomNames: s,
                concurrent: true,
              );
            },
            showSelectAll: true,
          ),
        ),
        const ReportDefaultNote(
          text: ReportsStrings.noteAllClassroomsWillBeSelectedByDefault,
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
        // The student list and its loading flag are cubit-owned
        // (§2.2 bucket A); only the selection is local.
        BlocSelector<
          ReportsCubit,
          ReportsState,
          ({List<String> items, bool loading})
        >(
          selector: (state) =>
              (items: state.studentNames, loading: state.formStudentsLoading),
          builder: (context, students) => ValueListenableBuilder<List<String>>(
            valueListenable: selectedStudents,
            builder: (_, selected, __) => MultiSelectFilterField<String>(
              label: ReportsStrings.tabStudent,
              hintText: students.loading
                  ? ReportsStrings.loadingStudents
                  : ReportsStrings.selectStudents,
              items: students.items,
              isRequired: true,
              selectedItems: selected,
              onChanged: (s) =>
                  selectedStudents.value = studentFilter.userSelected(s),
              itemToString: (item) => item,
              singularLabel: ReportsStrings.tabStudent,
              pluralLabel: ReportsStrings.students,
              showSelectAll: true,
              enableSearch: true,
              searchHintText: ReportsStrings.searchStudents,
            ),
          ),
        ),
        SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
      ],
    );
  }
}
