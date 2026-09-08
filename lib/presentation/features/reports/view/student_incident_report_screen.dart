import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
// import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class StudentIncidentReportScreen extends StatefulWidget {
  const StudentIncidentReportScreen({
    super.key,
    required this.students,
    this.classrooms = const [],
  });

  static const String routeName = '/reports/student/incident';

  /// Accepted and passed by the route, but no Classroom filter is rendered:
  /// the incident request omits `roomCodes` entirely.

  final List<String> students;
  final List<String> classrooms;

  @override
  State<StudentIncidentReportScreen> createState() =>
      _StudentIncidentReportScreenState();
}

class _StudentIncidentReportScreenState
    extends State<StudentIncidentReportScreen> {
  late final ValueNotifier<DateTime> _startDate;
  late final ValueNotifier<DateTime> _endDate;
  final ValueNotifier<List<String>> _selectedStudents =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _startDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _endDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));
  }

  @override
  void didUpdateWidget(covariant StudentIncidentReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students) {
      // Keep only selections that still exist; never re-select all.
      _selectedStudents.value = _selectedStudents.value
          .where(widget.students.contains)
          .toList();
    }
  }

  void _onGenerate() async {
    AppLogger.d('[INCIDENT-UI] Generate button tapped');

    if (_toDate.isBefore(_startDate.value)) {
      AppLogger.w('[INCIDENT-UI] Generation blocked: To date before From date');
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.endDateCannotBeBeforeStartDate,
        isError: true,
      );
      return;
    }

    AppLogger.d('[INCIDENT-UI] Creating report params');
    final cubit = context.read<ReportsCubit>();
    final studentNameToCode = cubit.state.studentNameToCode;
    final studentCodes = resolveReportCodes(
      context: context,
      names: _selectedStudents.value,
      nameToCode: studentNameToCode,
      labelPlural: 'students',
    );
    if (studentCodes == null) return;

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;
    final params = ReportRequestParams(
      reportType: ReportType.studentIncident,
      startDate: _startDate.value,
      endDate: _endDate.value,
      // Empty selection → `studentCodes` omitted, i.e. all students.
      studentCodes: studentCodes.isEmpty ? null : studentCodes,
      format: _format.value,
      schoolName: schoolName,
    );

    AppLogger.d('[INCIDENT-UI] Calling cubit.generateReport()');
    unawaited(cubit.generateReport(params));
  }

  DateTime get _toDate => _endDate.value;

  @override
  void dispose() {
    _endDate.dispose();
    _format.dispose();
    _selectedStudents.dispose();
    _startDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
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
                state.generationSuccess!.isNotEmpty) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: ReportsStrings.reportGeneratedSuccessfully,
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Hand the hub a typed result. The report is generated
                  // but the file is not attached, so the hub animates to the
                  // Generated tab -- the outcome pop(true) used to encode.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  context.pop(const ReportGeneratedRefreshList());
                });
              }
            }
          },
        ),
      ],
      child: BlocSelector<ReportsCubit, ReportsState, bool>(
        selector: (state) => state.isGenerating,
        builder: (context, isGenerating) {
          return ReportFormLayout(
            title: ReportsStrings.studentIncidentName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: ReportsStrings.startDate),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _startDate,
                  builder: (_, v, __) => CustomDateTimeField(
                    hasLabel: false,
                    dateFormat: 'MM/dd/yyyy',
                    fetchInitialTime: false,
                    initialDate: v,
                    onDateSelected: (d) => _startDate.value = d,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportFieldLabel(label: ReportsStrings.endDate),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _endDate,
                  builder: (_, v, __) => CustomDateTimeField(
                    hasLabel: false,
                    dateFormat: 'MM/dd/yyyy',
                    fetchInitialTime: false,
                    initialDate: v,
                    onDateSelected: (d) => _endDate.value = d,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedStudents,
                  builder: (_, v, __) => MultiSelectFilterField<String>(
                    label: ReportsStrings.tabStudent,
                    hintText: ReportsStrings.allStudents,
                    items: widget.students,
                    selectedItems: v,
                    onChanged: (s) => _selectedStudents.value = s,
                    itemToString: (item) => item,
                    singularLabel: ReportsStrings.tabStudent,
                    pluralLabel: ReportsStrings.students,
                    showSelectAll: true,
                    enableSearch: true,
                    searchHintText: ReportsStrings.searchStudents,
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllStudentsIncludedByDefault,
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportFieldLabel(label: ReportsStrings.exportFormat),
                ValueListenableBuilder<String>(
                  valueListenable: _format,
                  builder: (_, v, __) => ReportFormatSelector(
                    selectedFormat: v,
                    onFormatChanged: (value) => _format.value = value,
                    showLabel: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
