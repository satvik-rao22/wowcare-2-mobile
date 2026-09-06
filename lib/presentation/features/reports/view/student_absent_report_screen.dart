import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/classroom_range_report_submit.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class StudentAbsentReportScreen extends StatefulWidget {
  const StudentAbsentReportScreen({super.key, required this.classrooms});

  static const String routeName = '/reports/student/absent';

  final List<String> classrooms;

  @override
  State<StudentAbsentReportScreen> createState() =>
      _StudentAbsentReportScreenState();
}

class _StudentAbsentReportScreenState extends State<StudentAbsentReportScreen> {
  late final ValueNotifier<DateTime> _fromDate;
  late final ValueNotifier<DateTime> _toDate;
  late final ValueNotifier<List<String>> _selectedClassrooms;
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _fromDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _toDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));
    // All Classrooms are selected by default until the user changes it.
    _selectedClassrooms = ValueNotifier<List<String>>(
      List<String>.from(widget.classrooms),
    );
  }

  @override
  void dispose() {
    _fromDate.dispose();
    _toDate.dispose();
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() => submitClassroomRangeReport(
    context: context,
    reportType: ReportType.studentAbsent,
    fromDate: _fromDate.value,
    toDate: _toDate.value,
    format: _format.value,
    selectedClassrooms: _selectedClassrooms.value,
    fallbackClassrooms: widget.classrooms,
    logTag: 'STUDENT-ABSENT-UI',
    useWiderClassroomSet: false,
  );

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
            title: ReportsStrings.staffAbsentName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: ReportsStrings.from),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _fromDate,
                  builder: (_, date, __) => CustomDateTimeField(
                    hasLabel: false,
                    fetchInitialTime: false,
                    dateFormat: 'MM/dd/yyyy',
                    initialDate: date,
                    onDateSelected: (d) => _fromDate.value = d,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                const ReportFieldLabel(label: 'To'),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _toDate,
                  builder: (_, date, __) => CustomDateTimeField(
                    hasLabel: false,
                    dateFormat: 'MM/dd/yyyy',
                    fetchInitialTime: false,
                    initialDate: date,
                    onDateSelected: (d) => _toDate.value = d,
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: ReportsStrings.classroom,
                    hintText: ReportsStrings.selectClassroom,
                    items: widget.classrooms,
                    selectedItems: selected,
                    isRequired: true,
                    onChanged: (s) => _selectedClassrooms.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllClassroomsWillBeSelectedByDefault,
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
