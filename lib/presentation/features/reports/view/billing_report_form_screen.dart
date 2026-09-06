import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/model/report_filter_defaults.dart';
import 'package:wowcare/domain/features/reports/usecases/report_file_name_for_format.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/billing_invoice_filters.dart';
import 'package:wowcare/presentation/features/reports/widgets/billing_student_mapping_filters.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// Generic date-range + format form for the billing reports that don't need extra filters
/// (Invoice, Payment Summary, Outstanding, Refund, Students & Billing Mapping).
class BillingReportFormScreen extends StatefulWidget {
  const BillingReportFormScreen({
    super.key,
    required this.reportType,
    required this.title,
    this.classrooms = const <String>[],
    this.students = const <String>[],
  });

  final ReportType reportType;
  final String title;
  final List<String> classrooms;
  final List<String> students;

  @override
  State<BillingReportFormScreen> createState() =>
      _BillingReportFormScreenState();
}

class _BillingReportFormScreenState extends State<BillingReportFormScreen> {
  // §2.2 bucket B — form inputs and selections. Held as final notifier
  // fields (never created in build) and all disposed below, matching the
  // already-migrated forms in this module.
  late final ValueNotifier<DateTime> _startDate;
  late final ValueNotifier<DateTime> _endDate;
  late final ValueNotifier<DateTime> _periodDate;
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');
  final ValueNotifier<String> _folderClassGrouping = ValueNotifier<String>(
    'Daily',
  );
  final ValueNotifier<String> _periodType = ValueNotifier<String>('Monthly');
  final ValueNotifier<List<String>> _selectedStudents =
      ValueNotifier<List<String>>(<String>[]);
  late final ValueNotifier<List<String>> _selectedClassrooms;
  final ValueNotifier<List<String>> _selectedInvoiceStatuses =
      ValueNotifier<List<String>>(<String>[]);

  // §2.2 bucket A — the student list, its name→code map and the loading flag
  // are API-owned and now live on ReportsCubit. No local copies.

  final ReportFilterDefault _classroomFilter = ReportFilterDefault();
  final ReportFilterDefault _studentFilter = ReportFilterDefault();

  /// Only these report types render a classroom / student picker; the others
  /// (Payment Summary, Outstanding, Refund) have no such filter, so seeding a
  /// default selection for them would silently change their request payload.
  bool get _showsClassroomFilter =>
      widget.reportType == ReportType.billingInvoice ||
      widget.reportType == ReportType.billingStudentMapping;

  bool get _showsStudentFilter =>
      widget.reportType == ReportType.billingInvoice;

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _endDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));
    _periodDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    // All Classrooms / All Students are selected by default (on the forms
    // that expose those filters) until the user changes them.
    _selectedClassrooms = ValueNotifier<List<String>>(
      _showsClassroomFilter ? List<String>.from(widget.classrooms) : <String>[],
    );
    if (_showsStudentFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReportsCubit>().loadFormStudents(
          classroomNames: _selectedClassrooms.value,
          concurrent: true,
        );
      });
    }
  }

  @override
  void dispose() {
    _startDate.dispose();
    _endDate.dispose();
    _periodDate.dispose();
    _format.dispose();
    _folderClassGrouping.dispose();
    _periodType.dispose();
    _selectedStudents.dispose();
    _selectedClassrooms.dispose();
    _selectedInvoiceStatuses.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    DateTime reqStartDate = _startDate.value;
    DateTime? reqEndDate = _endDate.value;

    if (widget.reportType == ReportType.billingOutstanding) {
      reqEndDate = null;
    }

    if (widget.reportType == ReportType.billingStudentMapping &&
        _periodType.value == 'Monthly') {
      final period = _periodDate.value;
      reqStartDate = DateTime(period.year, period.month, 1);
      reqEndDate = DateTime(period.year, period.month + 1, 0, 23, 59, 59);
    }

    if (reqEndDate != null && reqEndDate.isBefore(reqStartDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.endDateCannotBeBeforeStartDate,
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final schoolName = await cubit.resolveSchoolName();
    final reportsState = cubit.state;

    final targetStudentNames = !_showsStudentFilter
        ? const <String>[]
        : _selectedStudents.value.isEmpty
        ? reportsState.studentNames
        : _selectedStudents.value;

    final studentCodes = targetStudentNames
        .map((name) => reportsState.studentNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final classroomNameToCode = await cubit.ensureClassroomNameToCode();

    final targetClassroomNames = _selectedClassrooms.value.isEmpty
        ? widget.classrooms
        : _selectedClassrooms.value;

    final classroomCodes = targetClassroomNames
        .map((name) => classroomNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    cubit.generateReport(
      ReportRequestParams(
        reportType: widget.reportType,
        startDate: reqStartDate,
        endDate: reqEndDate,
        format: _format.value,
        schoolName: schoolName.isNotEmpty ? schoolName : null,
        roomCodes: classroomCodes.isNotEmpty ? classroomCodes : null,
        studentCodes: studentCodes.isNotEmpty ? studentCodes : null,
        periodType: widget.reportType == ReportType.billingStudentMapping
            ? _periodType.value.toLowerCase()
            : null,
        folderClassGrouping:
            widget.reportType == ReportType.billingPaymentSummary
            ? _folderClassGrouping.value.toUpperCase()
            : null,
        invoiceStatuses:
            widget.reportType == ReportType.billingInvoice &&
                _selectedInvoiceStatuses.value.isNotEmpty
            ? _selectedInvoiceStatuses.value
                  .map((s) => s.toUpperCase())
                  .toList()
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
        // Re-resolve the student selection whenever the cubit publishes a new
        // student list. `resolve` returns [] for empty options, so this covers
        // all three branches the old fetch handled inline: no classrooms
        // selected, no resolvable classroom codes, and a successful fetch.
        BlocListener<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) =>
              previous.studentNames != current.studentNames,
          listener: (context, state) {
            _selectedStudents.value = _studentFilter.resolve(
              options: state.studentNames,
              current: _selectedStudents.value,
            );
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
        title: widget.title,
        onGenerate: _onGenerate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reportType == ReportType.billingStudentMapping)
              BillingStudentMappingFilters(
                classrooms: widget.classrooms,
                periodType: _periodType,
                periodDate: _periodDate,
                startDate: _startDate,
                endDate: _endDate,
                format: _format,
                selectedClassrooms: _selectedClassrooms,
                classroomFilter: _classroomFilter,
              )
            else if (widget.reportType == ReportType.billingOutstanding) ...[
              const ReportFieldLabel(label: ReportsStrings.asOfDate),
              ValueListenableBuilder<DateTime>(
                valueListenable: _startDate,
                builder: (_, startDate, __) => CustomDateTimeField(
                  hasLabel: false,
                  fetchInitialTime: false,
                  initialDate: startDate,
                  onDateSelected: (d) => _startDate.value = d,
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
            ] else ...[
              const ReportFieldLabel(label: ReportsStrings.startDate),
              ValueListenableBuilder<DateTime>(
                valueListenable: _startDate,
                builder: (_, startDate, __) => CustomDateTimeField(
                  hasLabel: false,
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
                  fetchInitialTime: false,
                  initialDate: endDate,
                  onDateSelected: (d) => _endDate.value = d,
                ),
              ),
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
            ],
            if (widget.reportType == ReportType.billingPaymentSummary) ...[
              ValueListenableBuilder<String>(
                valueListenable: _folderClassGrouping,
                builder: (_, grouping, __) => CustomDropdown(
                  label: ReportsStrings.grouping,
                  hintText: ReportsStrings.selectGrouping,
                  items: const ['Daily', 'Weekly', 'Monthly'],
                  initialValue: grouping,
                  onSelect: (value) {
                    if (value != null) {
                      _folderClassGrouping.value = value;
                    }
                  },
                ),
              ),
              SizedBox(height: context.responsive(compact: 16.0, medium: 24.0)),
            ],
            if (widget.reportType == ReportType.billingInvoice)
              BillingInvoiceFilters(
                classrooms: widget.classrooms,
                selectedInvoiceStatuses: _selectedInvoiceStatuses,
                selectedClassrooms: _selectedClassrooms,
                selectedStudents: _selectedStudents,
                classroomFilter: _classroomFilter,
                studentFilter: _studentFilter,
              ),
          ],
        ),
      ),
    );
  }
}
