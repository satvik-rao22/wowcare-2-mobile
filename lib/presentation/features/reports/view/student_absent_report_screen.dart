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
  final ValueNotifier<String> _format = ValueNotifier<String>('PDF');

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _fromDate = ValueNotifier<DateTime>(DateTime(now.year, now.month, 1));
    _toDate = ValueNotifier<DateTime>(DateTime(now.year, now.month + 1, 0));
    _selectedClassrooms = ValueNotifier<List<String>>([]);
  }

  @override
  void dispose() {
    _fromDate.dispose();
    _toDate.dispose();
    _selectedClassrooms.dispose();
    _format.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    if (_toDate.value.isBefore(_fromDate.value)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'To date cannot be before From date',
        isError: true,
      );
      return;
    }

    final cubit = context.read<ReportsCubit>();
    final classroomNameToCode = cubit.state.classroomNameToCode;
    final classroomCodes = resolveReportCodes(
      context: context,
      names: _selectedClassrooms.value.isEmpty
          ? widget.classrooms
          : _selectedClassrooms.value,
      nameToCode: classroomNameToCode,
      labelPlural: 'classrooms',
    );
    if (classroomCodes == null) return;
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
      reportType: ReportType.studentAbsent,
      startDate: _fromDate.value,
      endDate: _toDate.value,
      format: _format.value,
      schoolName: schoolName.isNotEmpty ? schoolName : null,
      roomCodes: classroomCodes.isEmpty ? null : classroomCodes,
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
            title: 'Absent Report',
            onGenerate: isGenerating ? null : _onGenerate,
            isLoading: isGenerating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReportFieldLabel(label: 'From'),
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
                SizedBox(height: responsive.verticalSpacing),
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
                SizedBox(height: responsive.verticalSpacing),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedClassrooms,
                  builder: (_, selected, __) => CustomMultiSelectDropdown(
                    label: 'Classroom',
                    hintText: 'Select Classroom',
                    items: widget.classrooms,
                    selectedItems: selected,
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
