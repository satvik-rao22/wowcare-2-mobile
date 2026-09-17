import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'dart:async';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/domain/features/reports/usecases/report_file_name_for_format.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class BillingTransactionReportScreen extends StatefulWidget {
  const BillingTransactionReportScreen({super.key});

  static const String routeName = '/reports/billing/transaction';

  @override
  State<BillingTransactionReportScreen> createState() =>
      _BillingTransactionReportScreenState();
}

class _BillingTransactionReportScreenState
    extends State<BillingTransactionReportScreen> {
  static const List<String> _transactionOptions = <String>[
    'Success',
    'Failed',
    'Refunded',
  ];

  static const List<String> _paymentMethodOptions = <String>[
    'Card',
    'ACH',
    'Cash',
  ];

  // §2.2 bucket B — form inputs. Final notifier fields, all disposed below.
  late final ValueNotifier<DateTime> _startDate;
  late final ValueNotifier<DateTime> _endDate;
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');
  // Payment methods and transaction statuses open with their first option
  // ticked.
  final ValueNotifier<List<String>> _selectedTransactionStatuses =
      ValueNotifier<List<String>>(<String>[_transactionOptions.first]);
  final ValueNotifier<List<String>> _selectedPaymentMethods =
      ValueNotifier<List<String>>(<String>[_paymentMethodOptions.first]);
  final ValueNotifier<List<String>> _selectedStudents =
      ValueNotifier<List<String>>(<String>[]);

  /// No Transaction Type filter is rendered, so this stays empty and the
  /// request omits `transactionTypes`.
  final List<String> _selectedTransactionTypes = <String>[];

  // §2.2 bucket A — the student list and its loading flag are API-owned and
  // live on ReportsCubit. No local copies.

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _endDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsCubit>().loadAllRoomStudents();
      }
    });
  }

  @override
  void dispose() {
    _startDate.dispose();
    _endDate.dispose();
    _format.dispose();
    _selectedTransactionStatuses.dispose();
    _selectedPaymentMethods.dispose();
    _selectedStudents.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    if (_endDate.value.isBefore(_startDate.value)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.endDateCannotBeBeforeStartDate,
        isError: true,
      );
      return;
    }

    final schoolName = await context.read<ReportsCubit>().resolveSchoolName();
    if (!mounted) return;

    final reportsState = context.read<ReportsCubit>().state;
    // Empty selection → no codes → every list key below is omitted, which is
    // how this endpoint expresses "all students / all transaction types /
    // all statuses / all payment methods".
    final studentCodes = resolveReportCodes(
      context: context,
      names: _selectedStudents.value,
      nameToCode: reportsState.studentNameToCode,
      labelPlural: 'students',
    );
    if (studentCodes == null) return;

    context.read<ReportsCubit>().generateReport(
      ReportRequestParams(
        reportType: ReportType.billingTransaction,
        startDate: _startDate.value,
        endDate: _endDate.value,
        format: _format.value,
        studentCodes: studentCodes.isEmpty ? null : studentCodes,
        schoolName: schoolName.isNotEmpty ? schoolName : null,
        transactionStatuses: _selectedTransactionStatuses.value.isNotEmpty
            ? _selectedTransactionStatuses.value
            : null,
        transactionTypes: _selectedTransactionTypes.isNotEmpty
            ? _selectedTransactionTypes
            : null,
        paymentMethods: _selectedPaymentMethods.value.isNotEmpty
            ? _selectedPaymentMethods.value
            : null,
      ),
    );
  }

  /// The billing endpoints stream the file back labelled `*.xlsx` whatever
  /// format was asked for, so re-label the generated report with the export
  /// format the user actually picked — the hub uses that name to save and open
  /// the file with the right handler.
  ReportEntity? _withSelectedFormatFileName(dynamic report) {
    if (report is! ReportEntity) return null;
    return report.copyWith(
      fileName: reportFileNameForFormat(report.fileName, _format.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Drop selections that no longer exist when the cubit publishes a new
        // student list. Never re-expands to "all" — an empty filter already
        // means every student.
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.studentNames != current.studentNames,
          listener: (context, state) {
            _selectedStudents.value = _selectedStudents.value
                .where(state.studentNameToCode.containsKey)
                .toList();
          },
        ),
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationError != current.generationError,
          listener: (context, state) {
            if (state.generationError != null &&
                state.generationError!.isNotEmpty) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: state.generationError!,
                isError: true,
              );
            }
          },
        ),
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.generationSuccess != current.generationSuccess,
          listener: (context, state) {
            if (state.generationSuccess != null &&
                state.generationSuccess!.isNotEmpty &&
                state.generatedReport != null) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: ReportsStrings.reportGeneratedSuccessfully,
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Hand the hub a typed result. Billing reports stream the
                  // file back with the response, so when there is an entity
                  // the hub downloads and opens it; without one it just
                  // returns to the Generated tab. Same two outcomes the old
                  // `pop(reportToReturn ?? true)` encoded.
                  final reportToReturn = _withSelectedFormatFileName(
                    state.generatedReport,
                  );
                  context.read<ReportsCubit>().clearGeneratedReport();
                  context.pop(
                    reportToReturn == null
                        ? const ReportGeneratedRefreshList()
                        : ReportGeneratedWithEntity(reportToReturn),
                  );
                });
              }
            }
          },
        ),
      ],
      child: ReportFormLayout(
        title: ReportsStrings.billingTransactionName,
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportFieldLabel(label: ReportsStrings.startDate),
            ValueListenableBuilder<DateTime>(
              valueListenable: _startDate,
              builder: (_, startDate, __) => CustomDateTimeField(
                hasLabel: false,
                dateFormat: "dd-MM-yyyy",
                fetchInitialTime: false,
                initialDate: startDate,
                onDateSelected: (d) => _startDate.value = d,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            const ReportFieldLabel(label: ReportsStrings.endDate),
            ValueListenableBuilder<DateTime>(
              valueListenable: _endDate,
              builder: (_, endDate, __) => CustomDateTimeField(
                hasLabel: false,
                dateFormat: "dd-MM-yyyy",
                fetchInitialTime: false,
                initialDate: endDate,
                onDateSelected: (d) => _endDate.value = d,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            const ReportFieldLabel(label: ReportsStrings.exportFormat),
            ValueListenableBuilder<String>(
              valueListenable: _format,
              builder: (_, format, __) => ReportFormatSelector(
                selectedFormat: format,
                onFormatChanged: (value) => _format.value = value,
                showLabel: false,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),

            ValueListenableBuilder<List<String>>(
              valueListenable: _selectedPaymentMethods,
              builder: (_, selected, __) => CustomMultiSelectDropdown(
                label: ReportsStrings.paymentMethod,
                hintText: ReportsStrings.allPaymentMethods,
                items: _paymentMethodOptions,
                selectedItems: selected,
                showSelectAll: true,
                onChanged: (s) => _selectedPaymentMethods.value = s,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),

            ValueListenableBuilder<List<String>>(
              valueListenable: _selectedTransactionStatuses,
              builder: (_, selected, __) => CustomMultiSelectDropdown(
                label: ReportsStrings.transactionStatus,
                hintText: ReportsStrings.allTransactionStatuses,
                items: _transactionOptions,
                selectedItems: selected,
                showSelectAll: true,
                onChanged: (s) => _selectedTransactionStatuses.value = s,
              ),
            ),
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),

            // No Transaction Type filter is rendered, so
            // `_selectedTransactionTypes` stays empty and the request omits
            // `transactionTypes`.
            SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            // Student Dropdown
            BlocSelector<
              ReportsCubit,
              ReportsState,
              ({List<String> items, bool loading})
            >(
              selector: (state) => (
                items: state.studentNames,
                loading: state.formStudentsLoading,
              ),
              builder: (context, students) =>
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _selectedStudents,
                    builder: (_, selected, __) =>
                        MultiSelectFilterField<String>(
                          label: ReportsStrings.tabStudent,
                          hintText: students.loading
                              ? ReportsStrings.loadingStudents
                              : ReportsStrings.allStudents,
                          items: students.items,
                          selectedItems: selected,
                          onChanged: (s) => _selectedStudents.value = s,
                          itemToString: (item) => item,
                          singularLabel: ReportsStrings.tabStudent,
                          pluralLabel: ReportsStrings.students,
                          showSelectAll: true,
                          enableSearch: true,
                          searchHintText: ReportsStrings.searchStudents,
                        ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
