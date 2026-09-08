import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/reports/widgets/resolve_school_name.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class StudentDailyAttendanceReportScreen extends StatefulWidget {
  const StudentDailyAttendanceReportScreen({
    super.key,
    required this.classrooms,
  });

  static const String routeName = '/reports/student/daily-attendance';

  final List<String> classrooms;

  @override
  State<StudentDailyAttendanceReportScreen> createState() =>
      _StudentDailyAttendanceReportScreenState();
}

class _StudentDailyAttendanceReportScreenState
    extends State<StudentDailyAttendanceReportScreen> {
  late final ValueNotifier<DateTime> _date;
  final ValueNotifier<List<String>> _selectedClassrooms =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _format = ValueNotifier<String>('XLSX');

  @override
  void initState() {
    super.initState();
    _date = ValueNotifier<DateTime>(AppTime.now());
  }

  @override
  void dispose() {
    _date.dispose();
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    final cubit = context.read<ReportsCubit>();

    final classroomNameToCode = cubit.state.classroomNameToCode;

    // Empty selection → no codes → `roomCodes: null` below omits the key,
    // which is how this endpoint expresses "all classrooms".
    final roomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value,
      nameToCode: classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (roomCodes == null) return;

    final schoolName = await resolveSchoolNameOrWarn(context);
    if (schoolName == null || !mounted) return;
    final params = ReportRequestParams(
      reportType: ReportType.studentDailyAttendance,
      startDate: _date.value,
      date: _date.value,
      format: _format.value, // PDF or XLSX
      roomCodes: roomCodes.isEmpty ? null : roomCodes,
      schoolName: schoolName,
    );

    unawaited(cubit.generateReport(params));
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
            title: ReportsStrings.studentDailyAttendanceName,
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: ReportsStrings.date),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _date,
                  builder: (_, date, __) => CustomDateTimeField(
                    dateFormat: 'MM/dd/yyyy',
                    hasLabel: false,
                    fetchInitialTime: false,
                    initialDate: date,
                    onDateSelected: (d) => _date.value = d,
                    lastDate: AppTime.now(),
                  ),
                ),
                SizedBox(
                  height: context.responsive(compact: 16.0, medium: 24.0),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: ReportsStrings.classroom,
                    hintText: ReportsStrings.allClassrooms,
                    items: widget.classrooms,
                    selectedItems: selected,
                    onChanged: (s) => _selectedClassrooms.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: ReportsStrings.noteAllClassroomsIncludedByDefault,
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
