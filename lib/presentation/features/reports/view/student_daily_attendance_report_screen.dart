import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/utils/report_code_resolver.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/school_context_helper.dart';

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
    // All Classrooms are selected by default until the user changes it.
    _selectedClassrooms.value = List<String>.from(widget.classrooms);
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

    final roomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value.isEmpty
          ? widget.classrooms
          : _selectedClassrooms.value,
      nameToCode: classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (roomCodes == null) return;

    // Retrieve the school name from storage
    final schoolName = await SchoolContextHelper.getSchoolName();
    AppLogger.d('resolvedSchoolName=$schoolName');
    if (schoolName == null || schoolName.isEmpty) {
      if (!mounted) return;

      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve school name',
        isError: true,
      );
      return;
    }
    final params = ReportRequestParams(
      reportType: ReportType.studentDailyAttendance,
      startDate: _date.value,
      date: _date.value,
      // endDate: _date.value,
      format: _format.value, // PDF or XLSX
      roomCodes: roomCodes.isEmpty ? null : roomCodes,
      schoolName: schoolName,
    );

    unawaited(cubit.generateReport(params));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

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
                message: 'Report generated successfully',
                isSuccess: true,
              );

              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  // Pop (not context.go) — this screen was pushed via plain
                  // Navigator.push, so only popping actually dismisses it;
                  // the hub's own .then((success) => tab 0) callback reacts
                  // to the pop(true) result.
                  context.read<ReportsCubit>().clearGeneratedReport();
                  Navigator.of(context).pop(true);
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
            title: 'Student Daily Attendance',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: 'Date'),
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
                SizedBox(height: responsive.verticalSpacing),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: 'Classroom',
                    hintText: 'Select Classroom',
                    items: widget.classrooms,
                    selectedItems: selected,
                    isRequired: true,
                    onChanged: (s) => _selectedClassrooms.value = s,
                    showSelectAll: true,
                  ),
                ),
                const ReportDefaultNote(
                  text: 'Note: All Classrooms will be selected by Default.',
                ),
                SizedBox(height: responsive.verticalSpacing),
                const ReportFieldLabel(label: 'Export Format'),
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
